#!/usr/bin/env python3
"""
Normalize option markers in final cleaned question JSON files.

Targets:
- Marker variants like (क)/(ख)/(ग)/(घ), (अ)/(ब)/(स)/(द), [..], fullwidth brackets
- Uppercase Latin marker variants (A-D) to lowercase (a-d)
- Devanagari numerals as markers (१-४) to (a-d)
- Replace "मूल्य संवर्धन" and "मूल्यवर्धन" with "Value Addition"

By default this runs in dry-run mode.

Usage:
  python tools/normalize_option_markers.py
  python tools/normalize_option_markers.py --apply
  python tools/normalize_option_markers.py --apply --input-dir assets/final_cleaned_questions
"""

from __future__ import annotations

import argparse
import json
import re
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions"
DEFAULT_REPORT = REPO_ROOT / "tools" / "reports" / "marker_normalization_report.json"


@dataclass
class Stats:
    files_scanned: int = 0
    files_changed: int = 0
    questions_scanned: int = 0
    strings_changed: int = 0
    replacements: int = 0

    def as_dict(self) -> dict[str, int]:
        return {
            "files_scanned": self.files_scanned,
            "files_changed": self.files_changed,
            "questions_scanned": self.questions_scanned,
            "strings_changed": self.strings_changed,
            "replacements": self.replacements,
        }


MARKER_RE = re.compile(r"([\(\[（【])\s*([^\)\]）】])\s*([\)\]）】])")

MARKER_MAP = {
    "a": "a",
    "b": "b",
    "c": "c",
    "d": "d",
    "A": "a",
    "B": "b",
    "C": "c",
    "D": "d",
    "क": "a",
    "ख": "b",
    "ग": "c",
    "घ": "d",
    "अ": "a",
    "ब": "b",
    "स": "c",
    "द": "d",
    "१": "a",
    "२": "b",
    "३": "c",
    "४": "d",
    "1": "a",
    "2": "b",
    "3": "c",
    "4": "d",
}


def normalize_marker_string(text: str) -> tuple[str, int]:
    replacements = 0

    def repl(match: re.Match[str]) -> str:
        nonlocal replacements
        marker = match.group(2)
        mapped = MARKER_MAP.get(marker)
        if mapped is None:
            return match.group(0)
        replacements += 1
        return f"({mapped})"

    updated = MARKER_RE.sub(repl, text)

    phrase_replacements = 0
    for src in ("मूल्य संवर्धन", "मूल्यवर्धन"):
        if src in updated:
            count = updated.count(src)
            updated = updated.replace(src, "Value Addition")
            phrase_replacements += count

    return updated, replacements + phrase_replacements


def normalize_value(value: Any, *, normalize_markers: bool) -> tuple[Any, int, int]:
    """
    Returns (new_value, replacement_count, changed_string_count)
    """
    if isinstance(value, str):
        if normalize_markers:
            updated, count = normalize_marker_string(value)
        else:
            updated = value
            count = 0
            for src in ("मूल्य संवर्धन", "मूल्यवर्धन"):
                if src in updated:
                    c = updated.count(src)
                    updated = updated.replace(src, "Value Addition")
                    count += c
        return updated, count, (1 if updated != value else 0)

    if isinstance(value, list):
        total_repl = 0
        total_changed = 0
        out = []
        for item in value:
            new_item, repl, changed = normalize_value(
                item,
                normalize_markers=normalize_markers,
            )
            total_repl += repl
            total_changed += changed
            out.append(new_item)
        return out, total_repl, total_changed

    if isinstance(value, dict):
        total_repl = 0
        total_changed = 0
        out: dict[str, Any] = {}
        for key, val in value.items():
            new_val, repl, changed = normalize_value(
                val,
                normalize_markers=normalize_markers,
            )
            total_repl += repl
            total_changed += changed
            out[key] = new_val
        return out, total_repl, total_changed

    return value, 0, 0


def process_question(question: dict[str, Any]) -> tuple[dict[str, Any], int, int]:
    # Apply marker + phrase normalization across all text fields so that
    # strings like "विकल्प (क)" inside elimination_logic also get normalized.
    q2, replacement_count, changed_strings = normalize_value(
        question,
        normalize_markers=True,
    )
    return q2, replacement_count, changed_strings


def process_file(path: Path, apply: bool) -> tuple[bool, int, int, int]:
    """
    Returns (changed_file, questions_scanned, replacements, changed_strings)
    """
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError):
        return False, 0, 0, 0

    if not isinstance(data, list):
        return False, 0, 0, 0

    questions_scanned = 0
    replacements = 0
    changed_strings = 0
    changed_file = False
    out = []

    for item in data:
        if not isinstance(item, dict):
            out.append(item)
            continue
        questions_scanned += 1
        updated, repl, changed = process_question(item)
        replacements += repl
        changed_strings += changed
        if updated != item:
            changed_file = True
        out.append(updated)

    if changed_file and apply:
        path.write_text(
            json.dumps(out, ensure_ascii=False, indent=2) + "\n",
            encoding="utf-8",
        )

    return changed_file, questions_scanned, replacements, changed_strings


def main() -> None:
    parser = argparse.ArgumentParser(description="Normalize option markers in question JSONs.")
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help=f"Input directory (default: {DEFAULT_INPUT_DIR})",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=DEFAULT_REPORT,
        help=f"Report path (default: {DEFAULT_REPORT})",
    )
    parser.add_argument(
        "--apply",
        action="store_true",
        help="Write changes to files (default is dry-run).",
    )
    args = parser.parse_args()

    input_dir = args.input_dir if args.input_dir.is_absolute() else (REPO_ROOT / args.input_dir)
    report_path = args.report if args.report.is_absolute() else (REPO_ROOT / args.report)

    if not input_dir.is_dir():
        raise SystemExit(f"Input directory not found: {input_dir}")

    stats = Stats()
    changed_files: list[str] = []
    for file_path in sorted(input_dir.rglob("*.json")):
        stats.files_scanned += 1
        changed, q_scanned, repl, changed_strings = process_file(file_path, args.apply)
        stats.questions_scanned += q_scanned
        stats.replacements += repl
        stats.strings_changed += changed_strings
        if changed:
            stats.files_changed += 1
            changed_files.append(str(file_path.relative_to(REPO_ROOT)))

    report = {
        "mode": "apply" if args.apply else "dry-run",
        "input_dir": str(input_dir),
        "summary": stats.as_dict(),
        "changed_files": changed_files,
    }
    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Mode: {report['mode']}")
    print(f"Files scanned: {stats.files_scanned}")
    print(f"Files changed: {stats.files_changed}")
    print(f"Questions scanned: {stats.questions_scanned}")
    print(f"Strings changed: {stats.strings_changed}")
    print(f"Replacements: {stats.replacements}")
    print(f"Report: {report_path}")


if __name__ == "__main__":
    main()
