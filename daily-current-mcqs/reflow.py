"""
reflow.py
Re-apply display formatting to an existing Firestore daily MCQ document.

Fixes line breaks in questions/explanations and normalizes table rows
without regenerating MCQs or re-translating.

Usage:
    python reflow.py --date 2026-06-05
    python reflow.py --date 2026-06-05 --dry-run
"""

import config.bootstrap  # noqa: F401 — silence google EOL warnings on Python 3.9

import argparse
import logging
from datetime import date, datetime

from services.firestore import document_exists, read_document, write_document
from services.formatter import format_all_questions

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


def reflow(target: date, dry_run: bool = False) -> None:
    date_str = target.strftime("%Y-%m-%d")
    log.info(f"═══ Reflow formatting for {date_str} ═══")

    if not document_exists(target):
        log.error(f"No Firestore document for {date_str}.")
        raise SystemExit(1)

    document = read_document(target)
    questions = document.get("questions", [])
    if not questions:
        log.error("Document has no questions.")
        raise SystemExit(1)

    log.info(f"Loaded {len(questions)} questions")
    questions = format_all_questions(questions)
    document["questions"] = questions

    metadata = document.setdefault("metadata", {})
    metadata["reflowed_at"] = datetime.utcnow().isoformat() + "Z"

    if dry_run:
        log.info("Dry run — Firestore not updated")
        return

    write_document(target, document)
    log.info(f"═══ Firestore updated with reflowed formatting for {date_str} ═══")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Re-apply display formatting to an existing daily MCQ document"
    )
    parser.add_argument("--date", required=True, help="Target date YYYY-MM-DD")
    parser.add_argument("--dry-run", action="store_true", help="Format only — no write")
    args = parser.parse_args()

    try:
        target = date.fromisoformat(args.date)
    except ValueError:
        print(f"Invalid date: {args.date}. Use YYYY-MM-DD.")
        raise SystemExit(1)

    reflow(target, dry_run=args.dry_run)
