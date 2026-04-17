#!/usr/bin/env python3
"""
Count negative framing labels in final_cleaned_questions_v2.

Scans JSON arrays under assets/final_cleaned_questions_v2/**.json (excluding
known analysis artifacts), and reports:
  - total questions
  - negative_framing = true
  - negative_framing = false
  - missing / invalid labels

Usage:
  python tools/count_negative_framing.py
  python tools/count_negative_framing.py --json
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
INPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions"
SKIP_NAMES = {"trap_analysis.json"}


@dataclass
class Counts:
    total: int = 0
    true_count: int = 0
    false_count: int = 0
    missing_or_invalid: int = 0
    files_scanned: int = 0

    def as_dict(self) -> dict[str, int]:
        return {
            "files_scanned": self.files_scanned,
            "total_questions": self.total,
            "negative_framing_true": self.true_count,
            "negative_framing_false": self.false_count,
            "missing_or_invalid_negative_framing": self.missing_or_invalid,
        }


def iter_question_files(root: Path) -> list[Path]:
    out: list[Path] = []
    for p in sorted(root.rglob("*.json")):
        if p.name in SKIP_NAMES:
            continue
        out.append(p)
    return out


def is_question_list(data: Any) -> bool:
    return isinstance(data, list) and all(isinstance(x, dict) for x in data)


def count_labels(root: Path) -> Counts:
    counts = Counts()
    for path in iter_question_files(root):
        try:
            data = json.loads(path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue

        if not is_question_list(data):
            continue

        counts.files_scanned += 1
        for q in data:
            counts.total += 1
            value = q.get("negative_framing")
            if isinstance(value, bool):
                if value:
                    counts.true_count += 1
                else:
                    counts.false_count += 1
            else:
                counts.missing_or_invalid += 1
    return counts


def main() -> None:
    parser = argparse.ArgumentParser(description="Count negative_framing labels in v2 questions.")
    parser.add_argument("--json", action="store_true", help="Print output as JSON.")
    args = parser.parse_args()

    if not INPUT_DIR.is_dir():
        raise SystemExit(f"Input directory not found: {INPUT_DIR}")

    counts = count_labels(INPUT_DIR)
    result = counts.as_dict()

    if args.json:
        print(json.dumps(result, indent=2))
        return

    print(f"Scanned files: {result['files_scanned']}")
    print(f"Total questions: {result['total_questions']}")
    print(f"negative_framing=true: {result['negative_framing_true']}")
    print(f"negative_framing=false: {result['negative_framing_false']}")
    print(f"missing/invalid negative_framing: {result['missing_or_invalid_negative_framing']}")


if __name__ == "__main__":
    main()
