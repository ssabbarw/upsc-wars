#!/usr/bin/env python3
"""
Count total number of questions across all cleaned JSON files.

Usage:
    python tools/count_questions.py

This walks assets/final_cleaned_questions/<subject>/*.json,
assumes each file is a list of question objects, and prints:
- per-subject totals
- grand total across all subjects.
"""

import json
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
QUESTIONS_ROOT = PROJECT_ROOT / "assets" / "final_cleaned_questions"


def main() -> None:
    if not QUESTIONS_ROOT.exists():
        print(f"[ERROR] Directory not found: {QUESTIONS_ROOT}")
        raise SystemExit(1)

    grand_total = 0
    total_files = 0

    for subject_dir in sorted(p for p in QUESTIONS_ROOT.iterdir() if p.is_dir()):
        subject_total = 0
        json_files = sorted(subject_dir.glob("*.json"))
        if not json_files:
            continue

        for jf in json_files:
            total_files += 1
            try:
                with jf.open("r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception as exc:  # pragma: no cover - defensive
                print(f"[WARN] Skipping unreadable file {jf}: {exc}")
                continue

            if isinstance(data, list):
                subject_total += len(data)
            else:
                print(
                    f"[WARN] {jf} has top-level {type(data).__name__}, "
                    "expected list; counting as 0."
                )

        grand_total += subject_total
        print(f"[INFO] Subject '{subject_dir.name}': {subject_total} questions")

    print(
        f"[DONE] Processed {total_files} file(s). "
        f"Total questions across all subjects: {grand_total}."
    )


if __name__ == "__main__":
    main()

