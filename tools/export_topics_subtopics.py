#!/usr/bin/env python3
"""
Export topics and subtopics from the question bank into a file.

Reads assets/final_cleaned_questions/<subject>/*.json (same source as
build_question_db.py) and writes a per-subject hierarchy of topics → subtopics.

Usage:
    python tools/export_topics_subtopics.py
    python tools/export_topics_subtopics.py --format txt
    python tools/export_topics_subtopics.py --output /path/to/report.json
"""

from __future__ import annotations

import argparse
import json
from collections import defaultdict
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_INPUT_DIR = PROJECT_ROOT / "assets" / "final_cleaned_questions"
DEFAULT_OUTPUT_DIR = PROJECT_ROOT / "tools" / "reports"
ASSET_CATALOG_PATH = PROJECT_ROOT / "assets" / "data" / "topics_and_subtopics.json"


def collect_topics_subtopics(input_dir: Path) -> dict[str, dict[str, list[str]]]:
    """Return {subject: {topic: [sub_topic, ...]}}."""
    if not input_dir.exists():
        raise FileNotFoundError(f"Directory not found: {input_dir}")

    seen: dict[str, dict[str, set[str]]] = defaultdict(
        lambda: defaultdict(set)
    )

    for subject_dir in sorted(p for p in input_dir.iterdir() if p.is_dir()):
        for json_file in sorted(subject_dir.glob("*.json")):
            try:
                with json_file.open("r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception as exc:
                print(f"[WARN] Skipping unreadable file {json_file}: {exc}")
                continue

            if not isinstance(data, list):
                print(
                    f"[WARN] {json_file} has top-level {type(data).__name__}, "
                    "expected list; skipping."
                )
                continue

            for item in data:
                if not isinstance(item, dict):
                    continue
                meta = item.get("meta")
                if not isinstance(meta, dict):
                    continue

                subject = str(meta.get("subject", "")).strip()
                topic = str(meta.get("topic", "")).strip()
                sub_topic = str(meta.get("sub_topic", "")).strip()

                if not subject or not topic or not sub_topic:
                    continue

                seen[subject][topic].add(sub_topic)

    out: dict[str, dict[str, list[str]]] = {}
    for subject in sorted(seen.keys(), key=lambda s: s.lower()):
        topics = seen[subject]
        out[subject] = {
            topic: sorted(subtopics, key=str.lower)
            for topic, subtopics in sorted(
                topics.items(),
                key=lambda pair: pair[0].lower(),
            )
        }
    return out


def write_json(
    output_path: Path,
    catalog: dict[str, dict[str, list[str]]],
) -> None:
    output_path.parent.mkdir(parents=True, exist_ok=True)
    with output_path.open("w", encoding="utf-8") as f:
        json.dump(catalog, f, ensure_ascii=False, indent=2)
        f.write("\n")


def write_txt(
    output_path: Path,
    catalog: dict[str, dict[str, list[str]]],
) -> None:
    lines: list[str] = []

    for subject, topics in catalog.items():
        lines.append(subject)
        for topic, subtopics in topics.items():
            lines.append(f"  {topic}")
            for sub_topic in subtopics:
                lines.append(f"    - {sub_topic}")
        lines.append("")

    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text("\n".join(lines), encoding="utf-8")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Export topics and subtopics from the question bank."
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help=f"Question JSON root (default: {DEFAULT_INPUT_DIR})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=None,
        help="Output file path (default: tools/reports/topics_and_subtopics.<ext>)",
    )
    parser.add_argument(
        "--format",
        choices=("json", "txt"),
        default="json",
        help="Output format (default: json)",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()
    input_dir = args.input_dir.resolve()
    output_path = (
        args.output.resolve()
        if args.output
        else DEFAULT_OUTPUT_DIR / f"topics_and_subtopics.{args.format}"
    )

    catalog = collect_topics_subtopics(input_dir)
    if not catalog:
        print(f"[ERROR] No topics found under {input_dir}")
        raise SystemExit(1)

    if args.format == "json":
        write_json(output_path, catalog)
        if output_path != ASSET_CATALOG_PATH.resolve():
            write_json(ASSET_CATALOG_PATH, catalog)
            print(f"[DONE] Also wrote {ASSET_CATALOG_PATH}")
    else:
        write_txt(output_path, catalog)

    topic_count = sum(len(topics) for topics in catalog.values())
    subtopic_count = sum(
        len(subtopics) for topics in catalog.values() for subtopics in topics.values()
    )
    print(f"[DONE] Wrote {output_path}")
    print(
        "[INFO] "
        f"{len(catalog)} subjects, "
        f"{topic_count} topics, "
        f"{subtopic_count} subtopics"
    )


if __name__ == "__main__":
    main()
