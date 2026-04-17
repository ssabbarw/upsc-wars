#!/usr/bin/env python3
"""
negative_framing_batch.py — Classify MCQ stem framing via OpenAI Batch API (gpt-4.1-mini).

Reads question JSON arrays from assets/final_cleaned_questions/ (mirrors subject/*.json).
Writes assets/final_cleaned_questions_v2/ with top-level field negative_framing: bool.

Up to FILES_PER_BATCH source JSON files are merged into a single Batch API job (one shared
input .jsonl); each line still uses custom_id rel_path::uuid for merge-back.

Stem text for the model:
  - No table: en.display_text
  - Table: en.table_data.header_text + en.table_data.footer_text
    (has_table is inferred from shared.has_table or non-null en.table_data)

Wave control (same idea as resubmit_failed_batches.py):
  - At most WAVE_SIZE concurrent batches in validating/in_progress/finalizing
  - Poll every POLL_INTERVAL seconds; refill as slots free
  - Retries with exponential backoff on API errors

Requires: pip install openai
Env: OPENAI_API_KEY

Usage:
  python tools/negative_framing_batch.py --init-mirror     # copy missing v1 -> v2 files once
  python tools/negative_framing_batch.py                   # submit + poll + merge
  python tools/negative_framing_batch.py --dry-run         # no API calls
  python tools/negative_framing_batch.py --force           # rebuild jsonl even if v2 has field
  python tools/negative_framing_batch.py --files-per-batch 5
"""

from __future__ import annotations

import argparse
import hashlib
import json
import logging
import os
import re
import shutil
import time
from collections import deque
from datetime import datetime
from pathlib import Path
from typing import Any

from openai import OpenAI

# ── paths (relative to repo root = parent of tools/) ─────────────────────
REPO_ROOT = Path(__file__).resolve().parent.parent
INPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions"
OUTPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions_v2"
META_DIR = REPO_ROOT / "assets" / "batch_negative_framing"
REQUESTS_DIR = META_DIR / "requests"
MANIFEST_PATH = META_DIR / "manifest.json"
LOG_PATH = META_DIR / "run.log"

MODEL = "gpt-4.1-mini"

# Number of question JSON files combined into one OpenAI Batch job (one .jsonl upload).
FILES_PER_BATCH = 10

WAVE_SIZE = 50
POLL_INTERVAL = 30
SLEEP_BETWEEN_SUB = 0.2
MAX_RETRIES = 6
BACKOFF_BASE = 1.5
BACKOFF_CAP = 30.0

ACTIVE_STATUSES = {"validating", "in_progress", "finalizing"}

SKIP_NAMES = {"trap_analysis.json"}

_system_prompt_cache: str | None = None

SYSTEM_PROMPT = """You classify whether a UPSC-style exam question uses negative framing.

Definition:
A question uses negative framing if it asks the candidate to identify what is false, incorrect,
not true, not applicable, wrongly matched, least appropriate, which option is the exception,
which is NOT among the listed items (odd one out), or cannot be inferred — or equivalent inverted
wording, even when indirect.

Affirmative framing means the stem asks which statements or options are correct, true, valid,
or accurately matched (including "which of the following is/are correct").

Classify from the overall question task (including multi-statement stems and table header/footer
instructions), not from incidental wording inside individual options.

Examples:

--- Example 1 — negative_framing: true ---
Which of the following is NOT a consequence of the RBI selling dollars?
--- end example ---

--- Example 2 — negative_framing: true ---
Which of the following is incorrectly matched?
--- end example ---

--- Example 3 — negative_framing: true ---
Which of the following cannot be inferred from the passage?
--- end example ---

--- Example 4 — negative_framing: false ---
Which of the following statements is/are correct?
--- end example ---

Instructions:
- Focus on intent, not just keywords.
- Return ONLY a single JSON object and no other text:
{"negative_framing": true}
or
{"negative_framing": false}
"""

USER_PROMPT_TEMPLATE = """Classify the following question stem for negative framing.

STEM:
---
{stem}
---
"""


def setup_logging() -> logging.Logger:
    META_DIR.mkdir(parents=True, exist_ok=True)
    REQUESTS_DIR.mkdir(parents=True, exist_ok=True)
    fmt = logging.Formatter("%(asctime)s  %(levelname)-8s  %(message)s", "%Y-%m-%d %H:%M:%S")

    file_handler = logging.FileHandler(LOG_PATH, encoding="utf-8", mode="a")
    file_handler.setLevel(logging.DEBUG)
    file_handler.setFormatter(fmt)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(fmt)

    logger = logging.getLogger("negative_framing")
    logger.setLevel(logging.DEBUG)
    logger.handlers.clear()
    logger.addHandler(file_handler)
    logger.addHandler(console_handler)
    return logger


def save_manifest(manifest: dict[str, Any]) -> None:
    MANIFEST_PATH.write_text(json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8")


def load_manifest() -> dict[str, Any]:
    if not MANIFEST_PATH.exists():
        return {"jobs": []}
    return json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))


def call_with_retry(fn, label: str, logger: logging.Logger):
    last_err = None
    for attempt in range(1, MAX_RETRIES + 1):
        try:
            return fn()
        except Exception as e:
            last_err = e
            if attempt >= MAX_RETRIES:
                break
            delay = min(BACKOFF_CAP, BACKOFF_BASE * (2 ** (attempt - 1)))
            logger.warning("%s — attempt %s/%s failed: %s (retry in %.1fs)", label, attempt, MAX_RETRIES, e, delay)
            time.sleep(delay)
    raise RuntimeError(f"{label} failed after {MAX_RETRIES} attempts: {last_err}")


def iter_question_files() -> list[Path]:
    out: list[Path] = []
    for p in sorted(INPUT_DIR.rglob("*.json")):
        if p.name in SKIP_NAMES:
            continue
        rel = p.relative_to(INPUT_DIR)
        if rel.parts[0].startswith("."):
            continue
        out.append(p)
    return out


def is_question_file(path: Path) -> bool:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return False
    return isinstance(data, list) and len(data) > 0 and isinstance(data[0], dict) and "uuid" in data[0]


def question_has_table(q: dict[str, Any]) -> bool:
    shared = q.get("shared") or {}
    en = q.get("en") or {}
    td = en.get("table_data")
    if shared.get("has_table") is True:
        return True
    return isinstance(td, dict) and bool(td)


def extract_stem_for_llm(q: dict[str, Any]) -> str:
    en = q.get("en") or {}
    td = en.get("table_data")
    if question_has_table(q) and isinstance(td, dict):
        header = (td.get("header_text") or "").strip()
        footer = (td.get("footer_text") or "").strip()
        parts = [x for x in (header, footer) if x]
        return "\n\n".join(parts).strip()
    return (en.get("display_text") or "").strip()


def get_system_prompt() -> str:
    global _system_prompt_cache
    if _system_prompt_cache is None:
        _system_prompt_cache = SYSTEM_PROMPT
    return _system_prompt_cache


def file_needs_work(path: Path, force: bool) -> bool:
    rel = path.relative_to(INPUT_DIR).as_posix()
    out_path = OUTPUT_DIR / rel
    if force:
        return True
    src = out_path if out_path.exists() else path
    try:
        data = json.loads(src.read_text(encoding="utf-8"))
    except (json.JSONDecodeError, OSError):
        return True
    if not isinstance(data, list):
        return True
    for q in data:
        if not isinstance(q, dict):
            return True
        if "negative_framing" not in q:
            return True
    return False


def init_mirror(logger: logging.Logger) -> None:
    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)
    n = 0
    for src in iter_question_files():
        if not is_question_file(src):
            continue
        rel = src.relative_to(INPUT_DIR)
        dst = OUTPUT_DIR / rel
        if dst.exists():
            continue
        dst.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(src, dst)
        n += 1
    logger.info("init-mirror: copied %s new files into %s", n, OUTPUT_DIR)


def build_request_body(stem: str) -> dict[str, Any]:
    user = USER_PROMPT_TEMPLATE.format(stem=stem if stem else "(empty stem)")
    return {
        "model": MODEL,
        "messages": [
            {"role": "system", "content": get_system_prompt()},
            {"role": "user", "content": user},
        ],
        "max_completion_tokens": 64,
        "response_format": {"type": "json_object"},
    }


def jsonl_lines_for_question_file(src_path: Path) -> list[str]:
    data = json.loads(src_path.read_text(encoding="utf-8"))
    assert isinstance(data, list)
    lines: list[str] = []
    rel = src_path.relative_to(INPUT_DIR).as_posix()
    for q in data:
        if not isinstance(q, dict) or "uuid" not in q:
            continue
        uid = q["uuid"]
        custom_id = f"{rel}::{uid}"
        stem = extract_stem_for_llm(q)
        body = build_request_body(stem)
        rec = {
            "custom_id": custom_id,
            "method": "POST",
            "url": "/v1/chat/completions",
            "body": body,
        }
        lines.append(json.dumps(rec, ensure_ascii=False))
    return lines


def bundle_request_path(rel_paths: list[str]) -> Path:
    digest = hashlib.sha256("\n".join(sorted(rel_paths)).encode("utf-8")).hexdigest()[:24]
    return REQUESTS_DIR / f"bundle_{digest}.jsonl"


def write_bundle_request_jsonl(rel_paths: list[str], dest: Path) -> int:
    all_lines: list[str] = []
    for rel in rel_paths:
        src = INPUT_DIR / rel
        if not src.exists():
            continue
        all_lines.extend(jsonl_lines_for_question_file(src))
    dest.parent.mkdir(parents=True, exist_ok=True)
    dest.write_text("\n".join(all_lines) + ("\n" if all_lines else ""), encoding="utf-8")
    return len(all_lines)


def job_bundle_key(j: dict[str, Any]) -> tuple[str, ...]:
    rp = j.get("rel_paths")
    if isinstance(rp, list) and rp:
        return tuple(sorted(str(x) for x in rp))
    r = j.get("rel_path")
    if r:
        return (str(r),)
    return tuple()


def job_needs_polling(j: dict[str, Any]) -> bool:
    if j.get("merged_at"):
        return False
    if not j.get("batch_id"):
        return False
    st = j.get("status")
    return st in ACTIVE_STATUSES or st == "completed"


def chunk_rels(sorted_rels: list[str], n: int) -> list[list[str]]:
    return [sorted_rels[i : i + n] for i in range(0, len(sorted_rels), n)]


def bundle_label(chunk: list[str]) -> str:
    if len(chunk) <= 2:
        return ", ".join(chunk)
    return ", ".join(chunk[:2]) + f", … (+{len(chunk) - 2} files)"


def sync_manifest_jobs_for_todos(
    manifest: dict[str, Any],
    todo_paths: list[Path],
    files_per_batch: int,
    force: bool,
    logger: logging.Logger,
) -> None:
    """One manifest job per bundle of up to `files_per_batch` question JSON files."""
    sorted_rels = sorted(p.relative_to(INPUT_DIR).as_posix() for p in todo_paths)
    chunks = chunk_rels(sorted_rels, files_per_batch)
    chunk_key_set = {tuple(sorted(c)) for c in chunks}

    old_jobs = list(manifest.get("jobs", []))
    by_key: dict[tuple[str, ...], dict[str, Any]] = {}
    for j in old_jobs:
        k = job_bundle_key(j)
        if k:
            by_key[k] = j

    rels_in_todos = set(sorted_rels)
    orphans: list[dict[str, Any]] = []
    for j in old_jobs:
        if not job_needs_polling(j):
            continue
        kb = job_bundle_key(j)
        if kb not in chunk_key_set:
            if len(kb) == 1 and kb[0] in rels_in_todos:
                logger.warning(
                    "dropping legacy single-file batch tracking for %s (file is rebundled)",
                    kb[0],
                )
                continue
            orphans.append(j)

    new_chunk_jobs: list[dict[str, Any]] = []
    for chunk in chunks:
        key_tuple = tuple(sorted(chunk))
        j = by_key.get(key_tuple)
        if j is None:
            j = {
                "rel_paths": list(chunk),
                "request_file": str(bundle_request_path(chunk).resolve()),
                "batch_id": None,
                "input_file_id": None,
                "status": None,
                "merged_at": None,
                "created_at": datetime.now().isoformat(),
            }
        else:
            j["rel_paths"] = list(chunk)
            j["request_file"] = str(bundle_request_path(chunk).resolve())
            j.setdefault("created_at", datetime.now().isoformat())

        if j.get("merged_at") and not force:
            needs = False
            for rel in chunk:
                p = INPUT_DIR / rel
                if p.exists() and file_needs_work(p, False):
                    needs = True
                    break
            if needs:
                logger.warning(
                    "reopening bundle — files still missing negative_framing: %s",
                    bundle_label(chunk),
                )
                j["merged_at"] = None
                j["batch_id"] = None
                j["input_file_id"] = None
                j["status"] = None

        if j.get("merged_at") and not force:
            continue

        st = j.get("status")
        if st in ACTIVE_STATUSES and j.get("batch_id"):
            new_chunk_jobs.append(j)
            continue

        req_path = Path(j["request_file"])
        n_lines = write_bundle_request_jsonl(chunk, req_path)
        j["line_count"] = n_lines
        if n_lines == 0:
            logger.warning("bundle has zero lines: %s", bundle_label(chunk))
        new_chunk_jobs.append(j)

    orphan_keys = {job_bundle_key(x) for x in new_chunk_jobs}
    orphans = [j for j in orphans if job_bundle_key(j) not in orphan_keys]

    manifest["jobs"] = orphans + new_chunk_jobs


def parse_negative_framing_from_content(content: str) -> bool | None:
    content = (content or "").strip()
    if not content:
        return None
    try:
        obj = json.loads(content)
        if isinstance(obj, dict) and "negative_framing" in obj:
            v = obj["negative_framing"]
            if isinstance(v, bool):
                return v
            if v in (0, 1):
                return bool(v)
    except json.JSONDecodeError:
        pass
    m = re.search(r'"negative_framing"\s*:\s*(true|false)', content, re.I)
    if m:
        return m.group(1).lower() == "true"
    return None


def merge_batch_output_file(
    output_jsonl_path: Path,
    logger: logging.Logger,
) -> dict[str, dict[str, bool]]:
    """Returns map rel_path -> {uuid: bool}."""
    by_file: dict[str, dict[str, bool]] = {}
    text = output_jsonl_path.read_text(encoding="utf-8")
    for line in text.splitlines():
        line = line.strip()
        if not line:
            continue
        row = json.loads(line)
        cid = row.get("custom_id") or ""
        if "::" not in cid:
            logger.warning("skip line: bad custom_id %r", cid)
            continue
        rel, uid = cid.split("::", 1)
        resp = row.get("response") or {}
        if resp.get("status_code") != 200:
            logger.error("non-200 for %s: %s", cid, resp)
            continue
        body = resp.get("body")
        if isinstance(body, str):
            body = json.loads(body)
        choices = (body or {}).get("choices") or []
        if not choices:
            logger.error("no choices for %s", cid)
            continue
        msg = choices[0].get("message") or {}
        raw = msg.get("content") or ""
        parsed = parse_negative_framing_from_content(raw)
        if parsed is None:
            logger.warning(
                "could not parse negative_framing uuid=%s rel=%s custom_id=%s (content=%r)",
                uid,
                rel,
                cid,
                raw[:200],
            )
            parsed = False
        by_file.setdefault(rel, {})[uid] = parsed
    return by_file


def apply_merge_to_v2(rel: str, uuid_to_flag: dict[str, bool], logger: logging.Logger) -> None:
    src = INPUT_DIR / rel
    dst = OUTPUT_DIR / rel
    if not src.exists():
        logger.error("missing source %s", src)
        return
    data = json.loads(src.read_text(encoding="utf-8"))
    assert isinstance(data, list)
    seen = set()
    for q in data:
        if not isinstance(q, dict):
            continue
        uid = q.get("uuid")
        if uid in uuid_to_flag:
            q["negative_framing"] = uuid_to_flag[uid]
            seen.add(uid)
    missing = set(uuid_to_flag) - seen
    if missing:
        logger.warning("%s: uuids in batch but not in source: %s", rel, list(missing)[:5])
    dst.parent.mkdir(parents=True, exist_ok=True)
    dst.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    logger.info("wrote %s (%s questions updated)", dst, len(seen))


def download_batch_output(client: OpenAI, batch, dest: Path, logger: logging.Logger) -> None:
    out_id = batch.output_file_id
    if not out_id:
        raise RuntimeError("completed batch has no output_file_id")
    content = call_with_retry(
        lambda: client.files.content(out_id).read(),
        f"download output {out_id}",
        logger,
    )
    dest.write_bytes(content)


def main() -> None:
    parser = argparse.ArgumentParser(description="Batch negative_framing labels via OpenAI Batch API.")
    parser.add_argument("--init-mirror", action="store_true", help="Copy missing question JSON from v1 to v2.")
    parser.add_argument(
        "--files-per-batch",
        type=int,
        default=FILES_PER_BATCH,
        help=f"Question JSON files per OpenAI Batch job (default: {FILES_PER_BATCH}).",
    )
    parser.add_argument("--wave-size", type=int, default=WAVE_SIZE)
    parser.add_argument("--poll-interval", type=int, default=POLL_INTERVAL)
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--force", action="store_true", help="Re-queue files that already have negative_framing.")
    args = parser.parse_args()
    logger = setup_logging()

    if args.init_mirror:
        init_mirror(logger)
        return

    if not INPUT_DIR.is_dir():
        raise SystemExit(f"Input dir missing: {INPUT_DIR}")

    OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    all_files = [p for p in iter_question_files() if is_question_file(p)]
    todo_paths = [p for p in all_files if file_needs_work(p, args.force)]

    manifest = load_manifest()
    if args.force:
        for j in manifest["jobs"]:
            j["batch_id"] = None
            j["input_file_id"] = None
            j["status"] = None
            j["merged_at"] = None

    sync_manifest_jobs_for_todos(manifest, todo_paths, args.files_per_batch, args.force, logger)
    save_manifest(manifest)

    client = None if args.dry_run else OpenAI(api_key=os.environ.get("OPENAI_API_KEY"))

    def merge_completed_job(job: dict[str, Any]) -> bool:
        """Download + merge a batch job that API reports completed. Returns True if merged."""
        if args.dry_run or client is None:
            return False
        bid = job.get("batch_id")
        if not bid:
            return False
        rel = bundle_label(job.get("rel_paths") or ([job["rel_path"]] if job.get("rel_path") else ["?"]))
        batch = call_with_retry(lambda: client.batches.retrieve(bid), f"retrieve {rel}", logger)
        if batch.status != "completed":
            job["status"] = batch.status
            save_manifest(manifest)
            return False
        out_tmp = META_DIR / "outputs" / f"{batch.id}.jsonl"
        out_tmp.parent.mkdir(parents=True, exist_ok=True)
        download_batch_output(client, batch, out_tmp, logger)
        by_file = merge_batch_output_file(out_tmp, logger)
        for f_rel, mapping in by_file.items():
            apply_merge_to_v2(f_rel, mapping, logger)
        job["merged_at"] = datetime.now().isoformat()
        job["output_file_local"] = str(out_tmp)
        job["status"] = "completed"
        save_manifest(manifest)
        return True

    # Finish any finished batches not yet merged from a prior run (does not consume wave slots).
    if client is not None:
        for j in list(manifest["jobs"]):
            if j.get("merged_at") or not j.get("batch_id"):
                continue
            try:
                if merge_completed_job(j):
                    logger.info("Startup merge: %s", bundle_label(j.get("rel_paths") or []))
            except Exception as exc:
                logger.error(
                    "Startup merge failed %s: %s",
                    bundle_label(j.get("rel_paths") or []),
                    exc,
                )

    # Submit queue: needs labels, not merged, not waiting on active batch
    submit_queue: deque[dict[str, Any]] = deque()
    todo_set = {p.relative_to(INPUT_DIR).as_posix() for p in todo_paths}

    for j in manifest["jobs"]:
        if j.get("merged_at"):
            continue
        rel_paths = j.get("rel_paths") or ([j["rel_path"]] if j.get("rel_path") else [])
        if not rel_paths or not todo_set.intersection(rel_paths):
            continue
        if j.get("line_count", 0) == 0:
            continue
        st = j.get("status")
        if st in ACTIVE_STATUSES:
            continue
        if st == "completed":
            continue
        if j.get("batch_id") is None or st in ("failed", "cancelled", "expired", None):
            submit_queue.append(j)

    active: list[dict[str, Any]] = []
    for j in manifest["jobs"]:
        if j.get("merged_at"):
            continue
        st = j.get("status")
        if not j.get("batch_id"):
            continue
        if st in ACTIVE_STATUSES:
            active.append(j)
        elif st == "completed":
            active.append(j)

    logger.info("=" * 64)
    logger.info("Input         : %s", INPUT_DIR)
    logger.info("Output        : %s", OUTPUT_DIR)
    logger.info("Manifest      : %s", MANIFEST_PATH)
    logger.info("Question files: %s  |  need work: %s", len(all_files), len(todo_paths))
    logger.info("Files / batch : %s", args.files_per_batch)
    logger.info("Submit queue  : %s", len(submit_queue))
    logger.info("Wave size     : %s", args.wave_size)
    logger.info("Poll interval : %ss", args.poll_interval)
    if args.dry_run:
        logger.info("DRY RUN: no uploads")
    logger.info("=" * 64)

    submitted = merged = refailed = 0
    wave_num = 0

    while submit_queue or active:
        while submit_queue and len(active) < args.wave_size:
            job = submit_queue.popleft()
            rel_paths = job.get("rel_paths") or ([job["rel_path"]] if job.get("rel_path") else [])
            rel = bundle_label(rel_paths) if rel_paths else "?"
            req_file = Path(job.get("request_file", ""))
            if not req_file.exists():
                logger.warning("SKIP %s — missing request file %s", rel, req_file)
                continue

            if args.dry_run:
                logger.info("DRY would submit %s", rel)
                job["status"] = "in_progress"
                active.append(job)
                submitted += 1
                continue

            assert client is not None
            try:
                input_file = call_with_retry(
                    lambda p=req_file: client.files.create(file=open(p, "rb"), purpose="batch"),
                    f"upload {rel}",
                    logger,
                )
                batch = call_with_retry(
                    lambda fid=input_file.id: client.batches.create(
                        input_file_id=fid,
                        endpoint="/v1/chat/completions",
                        completion_window="24h",
                        metadata={
                            "pipeline": "negative_framing",
                            "bundle": rel[:400],
                        },
                    ),
                    f"create batch {rel}",
                    logger,
                )
                job["batch_id"] = batch.id
                job["input_file_id"] = input_file.id
                job["status"] = batch.status
                job["submitted_at"] = datetime.now().isoformat()
                save_manifest(manifest)
                wave_num += 1
                submitted += 1
                active.append(job)
                logger.info("[%4s] submitted %-45s batch=%s", wave_num, rel, batch.id)
                time.sleep(SLEEP_BETWEEN_SUB)
            except Exception as exc:
                logger.error("FAILED submit %s: %s", rel, exc)

        if not active:
            break

        logger.info("Polling %s active jobs — sleep %ss...", len(active), args.poll_interval)
        if not args.dry_run:
            time.sleep(args.poll_interval)

        still_active: list[dict[str, Any]] = []
        counts: dict[str, int] = {}

        for job in active:
            rel_paths = job.get("rel_paths") or ([job["rel_path"]] if job.get("rel_path") else [])
            rel = bundle_label(rel_paths) if rel_paths else "?"
            if args.dry_run:
                still_active.append(job)
                counts["in_progress"] = counts.get("in_progress", 0) + 1
                continue

            assert client is not None
            try:
                batch = call_with_retry(
                    lambda bid=job["batch_id"]: client.batches.retrieve(bid),
                    f"poll {rel}",
                    logger,
                )
                new_status = batch.status
                if new_status != job.get("status"):
                    job["status"] = new_status
                    save_manifest(manifest)

                if new_status in ACTIVE_STATUSES:
                    still_active.append(job)
                    counts[new_status] = counts.get(new_status, 0) + 1
                elif new_status == "completed":
                    try:
                        out_tmp = META_DIR / "outputs" / f"{batch.id}.jsonl"
                        out_tmp.parent.mkdir(parents=True, exist_ok=True)
                        download_batch_output(client, batch, out_tmp, logger)
                        by_file = merge_batch_output_file(out_tmp, logger)
                        for f_rel, mapping in by_file.items():
                            apply_merge_to_v2(f_rel, mapping, logger)
                        job["merged_at"] = datetime.now().isoformat()
                        job["output_file_local"] = str(out_tmp)
                        save_manifest(manifest)
                        merged += 1
                        counts["completed"] = counts.get("completed", 0) + 1
                        logger.info("COMPLETED+MERGED %s", rel)
                    except Exception as exc:
                        logger.error("download/merge failed %s: %s", rel, exc)
                        still_active.append(job)
                elif new_status == "failed":
                    refailed += 1
                    counts["failed"] = counts.get("failed", 0) + 1
                    logger.warning("FAILED %s", rel)
                else:
                    counts["other"] = counts.get("other", 0) + 1
                    logger.warning("unexpected status %s for %s", new_status, rel)
            except Exception as exc:
                logger.error("poll error %s: %s", rel, exc)
                still_active.append(job)

        active = still_active
        summary = "  ".join(f"{k}:{v}" for k, v in sorted(counts.items()) if v)
        logger.info(
            "Poll — active=%s submit_queue=%s merged_total=%s | %s",
            len(active),
            len(submit_queue),
            merged,
            summary,
        )

        if args.dry_run:
            logger.info("DRY RUN: stopping after one poll cycle")
            break

    logger.info("=" * 64)
    logger.info("Submitted (this run): %s", submitted)
    logger.info("Merged batches       : %s", merged)
    logger.info("Failed               : %s", refailed)
    logger.info("Still active         : %s", len(active))


if __name__ == "__main__":
    main()
