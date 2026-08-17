"""
retranslate.py
Re-translate Hindi for an existing Firestore daily MCQ document.

Reads the document for a date, translates en → hi, and writes back.
Does not regenerate MCQs or touch any other pipeline steps.

Usage:
    python retranslate.py --date 2026-06-05
    python retranslate.py --date 2026-06-05 --dry-run
"""

import config.bootstrap  # noqa: F401 — silence google EOL warnings on Python 3.9

import argparse
import logging
from datetime import date, datetime

from config.settings import HAIKU_MODEL
from services.firestore import document_exists, read_document, write_document
from services.llm import translate_to_hindi
from services.transformer import add_hindi_to_questions
from services.formatter import format_all_questions

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(message)s",
    datefmt="%Y-%m-%d %H:%M:%S",
)
log = logging.getLogger(__name__)


def retranslate(target: date, dry_run: bool = False) -> None:
    date_str = target.strftime("%Y-%m-%d")
    log.info(f"═══ Hindi re-translation for {date_str} ═══")

    if not document_exists(target):
        log.error(f"No Firestore document for {date_str}. Run the pipeline first.")
        raise SystemExit(1)

    document = read_document(target)
    questions = document.get("questions", [])
    if not questions:
        log.error("Document has no questions.")
        raise SystemExit(1)

    log.info(f"Loaded {len(questions)} questions from Firestore")

    log.info("Formatting English display fields before translation...")
    questions = format_all_questions(questions)

    # Translate one question at a time to avoid output truncation on long explanations.
    hindi_questions = []
    for i, q in enumerate(questions, start=1):
        log.info(f"  Translating Q{i}/{len(questions)}...")
        translated = translate_to_hindi([q])
        hindi_questions.append(translated[0])
    log.info(f"Translated {len(hindi_questions)} questions")

    if len(hindi_questions) != len(questions):
        log.warning(
            f"Translation count mismatch: got {len(hindi_questions)}, "
            f"expected {len(questions)}"
        )

    questions = add_hindi_to_questions(questions, hindi_questions)
    log.info("Formatting Hindi display fields...")
    questions = format_all_questions(questions)
    document["questions"] = questions

    metadata = document.setdefault("metadata", {})
    metadata["hindi_available"] = all(q.get("hi") for q in questions)
    metadata["hindi_retranslated_at"] = datetime.utcnow().isoformat() + "Z"
    metadata["model_hi"] = HAIKU_MODEL

    filled = sum(1 for q in questions if q.get("hi"))
    log.info(f"Hindi sections filled: {filled}/{len(questions)}")

    if dry_run:
        log.info("Dry run — Firestore not updated")
        return

    write_document(target, document)
    log.info(f"═══ Firestore updated with Hindi for {date_str} ═══")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Re-translate Hindi for an existing daily MCQ Firestore document"
    )
    parser.add_argument(
        "--date",
        required=True,
        help="Target date in YYYY-MM-DD format",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="Translate only — do not write to Firestore",
    )
    args = parser.parse_args()

    try:
        target = date.fromisoformat(args.date)
    except ValueError:
        print(f"Invalid date: {args.date}. Use YYYY-MM-DD.")
        raise SystemExit(1)

    retranslate(target, dry_run=args.dry_run)
