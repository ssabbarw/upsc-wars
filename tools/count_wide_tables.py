#!/usr/bin/env python3
"""
Count questions whose table has more than N columns.

Scans question JSON files under assets/final_cleaned_questions (or a supplied input dir),
checks en.table_data.columns and hi.table_data.columns, and reports unique question UUIDs
where either language table has column count > threshold.

Usage:
  python tools/count_wide_tables.py
  python tools/count_wide_tables.py --max-columns 3
  python tools/count_wide_tables.py --input-dir assets/final_cleaned_questions_v1
"""

from __future__ import annotations

import argparse
import json
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions"
DEFAULT_REPORT_PATH = REPO_ROOT / "tools" / "reports" / "wide_tables_report.json"


@dataclass
class WideTableFinding:
    uuid: str
    subject: str
    topic: str
    file: str
    en_columns: int
    hi_columns: int

    def as_dict(self) -> dict[str, Any]:
        return {
            "uuid": self.uuid,
            "subject": self.subject,
            "topic": self.topic,
            "file": self.file,
            "en_columns": self.en_columns,
            "hi_columns": self.hi_columns,
        }


def _column_count(table_data: Any) -> int:
    if not isinstance(table_data, dict):
        return 0
    columns = table_data.get("columns")
    if isinstance(columns, list):
        return len(columns)
    return 0


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Count questions with table columns above threshold."
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help=f"Input directory (default: {DEFAULT_INPUT_DIR})",
    )
    parser.add_argument(
        "--max-columns",
        type=int,
        default=3,
        help="Flag tables with more than this many columns (default: 3)",
    )
    parser.add_argument(
        "--report",
        type=Path,
        default=DEFAULT_REPORT_PATH,
        help=f"Output JSON report path (default: {DEFAULT_REPORT_PATH})",
    )
    args = parser.parse_args()

    input_dir = args.input_dir if args.input_dir.is_absolute() else (REPO_ROOT / args.input_dir)
    report_path = args.report if args.report.is_absolute() else (REPO_ROOT / args.report)
    threshold = args.max_columns

    if threshold < 1:
        raise SystemExit("--max-columns must be >= 1")
    if not input_dir.is_dir():
        raise SystemExit(f"Input directory not found: {input_dir}")

    findings: list[WideTableFinding] = []
    total_questions = 0
    total_table_questions = 0

    for file_path in sorted(input_dir.rglob("*.json")):
        try:
            data = json.loads(file_path.read_text(encoding="utf-8"))
        except (OSError, json.JSONDecodeError):
            continue
        if not isinstance(data, list):
            continue

        for item in data:
            if not isinstance(item, dict):
                continue
            total_questions += 1

            shared = item.get("shared")
            has_table = isinstance(shared, dict) and bool(shared.get("has_table") is True)
            if not has_table:
                continue
            total_table_questions += 1

            en = item.get("en") if isinstance(item.get("en"), dict) else {}
            hi = item.get("hi") if isinstance(item.get("hi"), dict) else {}
            en_cols = _column_count(en.get("table_data"))
            hi_cols = _column_count(hi.get("table_data"))

            if en_cols > threshold or hi_cols > threshold:
                meta = item.get("meta") if isinstance(item.get("meta"), dict) else {}
                findings.append(
                    WideTableFinding(
                        uuid=str(item.get("uuid") or ""),
                        subject=str(meta.get("subject") or ""),
                        topic=str(meta.get("topic") or ""),
                        file=str(file_path.relative_to(REPO_ROOT)),
                        en_columns=en_cols,
                        hi_columns=hi_cols,
                    )
                )

    report = {
        "input_dir": str(input_dir),
        "max_columns": threshold,
        "summary": {
            "questions_scanned": total_questions,
            "table_questions_scanned": total_table_questions,
            "questions_with_more_than_max_columns": len(findings),
        },
        "findings": [f.as_dict() for f in findings],
    }

    report_path.parent.mkdir(parents=True, exist_ok=True)
    report_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")

    print(f"Questions scanned: {total_questions}")
    print(f"Table questions scanned: {total_table_questions}")
    print(f"Questions with > {threshold} columns: {len(findings)}")
    print(f"Report: {report_path}")


if __name__ == "__main__":
    main()
