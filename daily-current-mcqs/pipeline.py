"""
pipeline.py
Entry point. Orchestrates the full daily MCQ pipeline.

Steps:
    1. Build and validate source URLs (Sunday = Sat + Sun pages)
    2. Harvest distinct news topics (one search call)
    3. Generate 1 English MCQ per topic, 2–3 topics per call
    4. Transform → draft schema (GS subject + CA tags)
    5. Format EN display fields
    6. Write daily_ca_drafts/{YYYY-MM-DD} (no Hindi)
    7. Email + FCM the admin

Saturday is skipped. Hindi runs later when the admin publishes 5–10 items.

Cron (GitHub Actions): 8pm IST Mon–Fri and Sunday (14:30 UTC).

Run:
    python pipeline.py
    python pipeline.py --date 2026-06-05
    python pipeline.py --questions 5
    python pipeline.py --dry-run
    python pipeline.py --local --questions 6
    python preview.py --questions 6
"""

import config.bootstrap  # noqa: F401 — silence google EOL warnings on Python 3.9

import json
import logging
import argparse
from pathlib import Path

from datetime import date, datetime, timedelta
from config.settings import (
    QUESTIONS_TARGET,
    WEEKEND_QUESTIONS_TARGET,
    QUESTIONS_MIN,
    QUESTIONS_MAX,
    MIN_QUESTIONS_TO_WRITE,
    PROMPT_VERSION,
    ADMIN_NOTIFY_EMAIL,
    MCQ_MODEL,
)
from services.url_builder   import build_urls, validate_urls
from services.llm           import generate_mcqs
from services.transformer   import transform_all_questions, build_draft_document
from services.formatter     import format_all_questions
from services.firestore     import write_draft, notify_admin_fcm
from services.email_service import PipelineReport

logging.basicConfig(
    level   = logging.INFO,
    format  = "%(asctime)s %(levelname)s %(message)s",
    datefmt = "%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)
PREVIEW_DIR = Path(__file__).resolve().parent / "preview"


def write_local_preview(document: dict) -> Path:
    PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
    out = PREVIEW_DIR / "latest.json"
    out.write_text(
        json.dumps(document, indent=2, ensure_ascii=False, default=str),
        encoding="utf-8",
    )
    log.info(f"Local preview JSON → {out}")
    return out


def _notify_admin(date_str: str, question_count: int, failed: bool):
    title = (
        f"CA draft failed — {date_str}"
        if failed
        else f"CA review ready — {date_str}"
    )
    body = (
        "Generation failed. Check the pipeline email."
        if failed
        else f"{question_count} English drafts ready. Pick 5–10 and publish."
    )
    try:
        notify_admin_fcm(
            ADMIN_NOTIFY_EMAIL,
            title,
            body,
            {
                "kind": "daily_ca_review",
                "date": date_str,
            },
        )
    except Exception as e:
        log.warning(f"Admin FCM failed: {e}")


def run(today: date = None, questions_target: int = None, local: bool = False):
    if today is None:
        today = date.today()

    # Saturday: no generation. Sunday: Sat+Sun news, 20 questions.
    if today.weekday() == 5:
        log.info(f"Saturday {today.isoformat()} — skip generation")
        return

    is_weekend_pack = today.weekday() == 6
    if questions_target is None:
        questions_target = (
            WEEKEND_QUESTIONS_TARGET if is_weekend_pack else QUESTIONS_TARGET
        )

    date_str  = today.strftime("%Y-%m-%d")
    start     = datetime.now()
    report    = PipelineReport(date_str)

    log.info(
        f"═══ UPSC MCQ Pipeline starting — {date_str} "
        f"({questions_target} questions"
        f"{', weekend pack' if is_weekend_pack else ''}) ═══"
    )

    try:
        # ── Step 1: Build and validate URLs ───────────────────────────────────
        dates_for_urls = [today]
        if is_weekend_pack:
            dates_for_urls = [today - timedelta(days=1), today]

        all_urls = []
        seen = set()
        for d in dates_for_urls:
            for u in build_urls(d):
                if u["url"] in seen:
                    continue
                seen.add(u["url"])
                all_urls.append(u)

        reachable_urls, failed = validate_urls(all_urls)

        for u in failed:
            report.add_warning(f"URL unreachable — {u['name']}: {u['url']}")

        if not reachable_urls:
            report.add_error("All source URLs unreachable. No questions generated.")
            if not local:
                _notify_admin(date_str, 0, failed=True)
            return

        # ── Step 2: Harvest topics, then 1 MCQ each ───────────────────────────
        try:
            raw_data = generate_mcqs(
                today_str        = today.strftime("%B %d, %Y"),
                reachable_urls   = reachable_urls,
                questions_target = questions_target,
            )
        except Exception as e:
            report.add_error(f"MCQ generation failed: {e}")
            if not local:
                _notify_admin(date_str, 0, failed=True)
            return

        raw_questions  = raw_data.get("questions", [])
        log.info(f"Generated {len(raw_questions)} raw questions")

        # ── Step 3: Transform LLM output → Firestore schema ───────────────────
        month_str = today.strftime("%Y-%m")
        transformed = transform_all_questions(
            raw_questions         = raw_questions,
            current_affairs_date  = date_str,
            current_affairs_month = month_str,
        )
        question_count = len(transformed)
        log.info(f"{question_count} questions passed validation")

        skipped = len(raw_questions) - question_count
        if skipped > 0:
            report.add_warning(f"{skipped} questions failed validation and were skipped")

        # ── Quality gate ───────────────────────────────────────────────────────
        below_min = question_count < MIN_QUESTIONS_TO_WRITE
        if below_min and not local:
            report.add_error(
                f"Only {question_count} valid questions — below minimum "
                f"{MIN_QUESTIONS_TO_WRITE}. Nothing written to Firestore."
            )
            _notify_admin(date_str, question_count, failed=True)
            return
        if below_min and local:
            report.add_warning(
                f"Only {question_count} valid questions — writing local preview anyway."
            )

        if question_count < questions_target:
            report.add_warning(
                f"Below target: {question_count}/{questions_target} questions generated"
            )

        # ── Step 4: Format EN display fields (no Hindi until publish) ────────
        log.info("Formatting English display fields...")
        transformed = format_all_questions(transformed)

        document = build_draft_document(
            transformed_questions = transformed,
            raw_data              = raw_data,
            reachable_urls        = reachable_urls,
            failed_urls           = failed,
            target_date           = today,
            prompt_version        = PROMPT_VERSION,
            sonnet_model          = MCQ_MODEL,
            is_weekend_pack       = is_weekend_pack,
        )
        document["selected_topics"] = raw_data.get("selected_topics") or []

        if local:
            write_local_preview(document)
            log.info(
                f"═══ Local preview ready — {question_count} English questions. "
                "Run: python preview.py --serve-only"
            )
            return

        try:
            write_draft(date_str, document)
            log.info("Draft write complete")
        except Exception as e:
            report.add_error(f"Firestore draft write failed: {e}")
            _notify_admin(date_str, question_count, failed=True)
            return

        subjects = list(set(q["meta"].get("gs_subject", "") for q in transformed))
        report.mark_success(
            question_count   = question_count,
            questions_target = questions_target,
            subjects         = subjects,
            reachable_sources= [u["name"] for u in reachable_urls],
            failed_sources   = [u["name"] for u in failed],
            hindi_ok         = False,
        )
        _notify_admin(date_str, question_count, failed=False)
        log.info(f"═══ Draft ready — {question_count} English questions ═══")

    except Exception as e:
        report.add_error(f"Unexpected pipeline error: {e}")
        log.exception("Pipeline crashed")
        if not local:
            _notify_admin(date_str, 0, failed=True)

    finally:
        if not local:
            report.send_summary(start=start, end=datetime.now())


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="UPSC Daily MCQ Pipeline")
    parser.add_argument(
        "--date",
        type=str,
        default=None,
        help="Target date in YYYY-MM-DD format. Defaults to today.",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Validate URLs only — no API calls, no Firestore write.",
    )
    parser.add_argument(
        "--questions",
        type=int,
        default=None,
        help=(
            f"Number of MCQs to generate ({QUESTIONS_MIN}-{QUESTIONS_MAX}). "
            f"Defaults to QUESTIONS_TARGET env ({QUESTIONS_TARGET})."
        ),
    )
    parser.add_argument(
        "--local",
        action="store_true",
        help="Generate to preview/latest.json — no Firestore, email, or FCM.",
    )
    args = parser.parse_args()

    if args.date:
        try:
            target = date.fromisoformat(args.date)
        except ValueError:
            print(f"Invalid date: {args.date}. Use YYYY-MM-DD.")
            exit(1)
    else:
        target = date.today()

    questions_target = args.questions
    if questions_target is not None and not QUESTIONS_MIN <= questions_target <= QUESTIONS_MAX:
        print(
            f"Invalid --questions value: {questions_target}. "
            f"Must be between {QUESTIONS_MIN} and {QUESTIONS_MAX}."
        )
        exit(1)

    if args.dry_run:
        log.info(f"Dry run for {target}")
        urls = build_urls(target)
        reachable, failed = validate_urls(urls)
        log.info(f"Reachable: {[u['name'] for u in reachable]}")
        log.info(f"Failed:    {[u['name'] for u in failed]}")
    else:
        run(target, questions_target=questions_target, local=args.local)