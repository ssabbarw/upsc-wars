#!/usr/bin/env python3
"""
Batch replace exact text using a key->value map across question JSON files.

Default scope:
  assets/final_cleaned_questions/**/*.json

Usage:
  # Dry-run (default)
  python tools/replace_text_from_map.py

  # Apply changes
  python tools/replace_text_from_map.py --apply

  # Custom input dir
  python tools/replace_text_from_map.py --apply --input-dir assets/final_cleaned_questions_v1
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions"
DEFAULT_REPORT_PATH = REPO_ROOT / "tools" / "reports" / "replace_text_from_map_report.json"


# ---------------------------------------------------------------------------
# Exact text replacements:
# - Key: text to find (exact substring match)
# - Value: text to replace it with
# ---------------------------------------------------------------------------
REPLACEMENTS: dict[str, str] = {
    # Example provided by user
    '"strong_distractor": "ख': '"strong_distractor": "b',

    # Common label normalization
    "मूल्य संवर्धन": "Value Addition",
    "मूल्यवर्धन": "Value Addition",

    # Option marker normalization (exact bracketed markers)
    "(क)": "(a)",
    "(ख)": "(b)",
    "(ग)": "(c)",
    "(घ)": "(d)",
    "(अ)": "(a)",
    "(ब)": "(b)",
    "(स)": "(c)",
    "(द)": "(d)",
    "[क]": "[a]",
    "[ख]": "[b]",
    "[ग]": "[c]",
    "[घ]": "[d]",
    "[अ]": "[a]",
    "[ब]": "[b]",
    "[स]": "[c]",
    "[द]": "[d]",
}


@dataclass
class Summary:
    files_scanned: int = 0
    files_changed: int = 0
    total_replacements: int = 0

    def as_dict(self) -> dict[str, int]:
        return {
            "files_scanned": self.files_scanned,
            "files_changed": self.files_changed,
            "total_replacements": self.total_replacements,
        }


def replace_all(text: str, mapping: dict[str, str]) -> tuple[str, int]:
    updated = text
    replacement_count = 0
    for old, new in mapping.items():
        if old in updated:
            count = updated.count(old)
            updated = updated.replace(old, new)
            replacement_count += count
    return updated, replacement_count


def main() -> None:
    parser = argparse.ArgumentParser(description="Replace exact text using a key-value map.")
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help=f"Input directory (default: {DEFAULT_INPUT_DIR})",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=DEFAULT_REPORT_PATH,
        help=f"Report output path (default: {DEFAULT_REPORT_PATH})",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes to files. If omitted, runs as dry-run.",
    )
    args = parser.parse_args()

    input_dir = args.input_dir if args.input_dir.is_absolute() else (REPO_ROOT / args.input_dir)
    report_path = args.report if args.report.is_absolute() else (REPO_ROOT / args.report)
    if not input_dir.is_dir():
        raise SystemExit(f"Input directory not found: {input_dir}")

    summary = Summary()
    changed_files: list[dict[str, object]] = []

    for json_path in sorted(input_dir.rglob("*.json")):
        summary.files_scanned += 1
        try:
            original = json_path.read_text(encoding="utf-8")
        except OSError:
            continue

        updated, replacement_count = replace_all(original, REPLACEMENTS)
        if replacement_count == 0:
            continue

        summary.files_changed += 1
        summary.total_replacements += replacement_count
        changed_files.append(
            {
                "file": str(json_path.relative_to(REPO_ROOT)),
                "replacement_count": replacement_count,
            }
        )

        if args.apply:
            json_path.write_text(updated, encoding="utf-8")

    report = {
        "mode": "apply" if args.apply else "dry-run",
        "input_dir": str(input_dir),
        "replacement_map_size": len(REPLACEMENTS),
        "summary": summary.as_dict(),
        "changed_files": changed_files,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Mode: {report['mode']}")
    print(f"Files scanned: {summary.files_scanned}")
    print(f"Files changed: {summary.files_changed}")
    print(f"Total replacements: {summary.total_replacements}")
    print(f"Report: {report_path}")


if __name__ == "__main__":
    main()
