#!/usr/bin/env python3
"""
Validate question records that may be dropped at runtime.

This script mirrors the app's QuestionDisplayTextParser behavior and flags
questions that would fail option parsing (a/b/c/d) or have missing display text.

Usage:
  python tools/validate_question_integrity.py
  python tools/validate_question_integrity.py --input-dir assets/final_cleaned_questions
  python tools/validate_question_integrity.py --output tools/reports/integrity_report.json
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from dataclasses import dataclass
from pathlib import Path
from typing import Any


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_INPUT_DIR = REPO_ROOT / "assets" / "final_cleaned_questions"
DEFAULT_OUTPUT_PATH = REPO_ROOT / "tools" / "reports" / "question_integrity_report.json"

# Mirrors lib/core/parsers/question_display_text_parser.dart
MARKER = re.compile(r"^\s*[\(\[]([a-dA-D])[\)\]]\s+", re.MULTILINE)


@dataclass(frozen=True)
class Finding:
    uuid: str
    subject: str
    topic: str
    checks: list[str]

    def as_dict(self) -> dict[str, Any]:
        return {
            "uuid": self.uuid,
            "subject": self.subject,
            "topic": self.topic,
            "checks": self.checks,
        }


def parse_display_text(raw: str) -> dict[str, str]:
    """Replicate QuestionDisplayTextParser.parse logic from Dart."""
    matches = list(MARKER.finditer(raw))
    if len(matches) < 4:
        return {
            "stem": raw.strip(),
            "optionA": "",
            "optionB": "",
            "optionC": "",
            "optionD": "",
        }

    ordered: dict[str, str] = {}
    first_start = matches[0].start()
    stem = raw[:first_start].strip()

    for i, current in enumerate(matches):
        key = (current.group(1) or "").lower()
        value_start = current.end()
        value_end = matches[i + 1].start() if i + 1 < len(matches) else len(raw)
        if key not in ordered:
            ordered[key] = raw[value_start:value_end].strip()

    if not all(k in ordered for k in ("a", "b", "c", "d")):
        return {
            "stem": raw.strip(),
            "optionA": "",
            "optionB": "",
            "optionC": "",
            "optionD": "",
        }

    return {
        "stem": stem if stem else raw.strip(),
        "optionA": ordered.get("a", ""),
        "optionB": ordered.get("b", ""),
        "optionC": ordered.get("c", ""),
        "optionD": ordered.get("d", ""),
    }


def validate_question_display(
    en_display: str,
    hi_display: str,
    has_table: bool,
) -> list[str]:
    checks: list[str] = []
    en_display = en_display.strip()
    hi_display = hi_display.strip()

    # Table questions are expected to have display text in table_data, so
    # missing plain display_text is not treated as an issue for has_table=true.
    if not en_display and not has_table:
        checks.append("missing_en_display_text")
    if not hi_display and not has_table:
        checks.append("missing_hi_display_text")

    if en_display:
        parsed_en = parse_display_text(en_display)
        if not all(
            parsed_en[k].strip()
            for k in ("optionA", "optionB", "optionC", "optionD")
        ):
            checks.append("en_parse_missing_options")
    if hi_display:
        parsed_hi = parse_display_text(hi_display)
        if not all(
            parsed_hi[k].strip()
            for k in ("optionA", "optionB", "optionC", "optionD")
        ):
            checks.append("hi_parse_missing_options")

    return checks


def run_validation(input_dir: Path) -> dict[str, Any]:
    files = sorted(input_dir.rglob("*.json"))

    findings: list[Finding] = []
    by_subject: Counter[str] = Counter()
    by_check: Counter[str] = Counter()
    by_subject_topic: Counter[str] = Counter()
    total_questions = 0

    for file_path in files:
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
            meta = item.get("meta") if isinstance(item.get("meta"), dict) else {}
            en = item.get("en") if isinstance(item.get("en"), dict) else {}
            hi = item.get("hi") if isinstance(item.get("hi"), dict) else {}
            shared = item.get("shared") if isinstance(item.get("shared"), dict) else {}

            uuid = str(item.get("uuid") or "")
            subject = str(meta.get("subject") or "Unknown Subject")
            topic = str(meta.get("topic") or "Unknown Topic")
            en_display = str(en.get("display_text") or "")
            hi_display = str(hi.get("display_text") or "")
            has_table = bool(shared.get("has_table") is True)

            checks = validate_question_display(en_display, hi_display, has_table)
            if not checks:
                continue

            finding = Finding(
                uuid=uuid,
                subject=subject,
                topic=topic,
                checks=sorted(set(checks)),
            )
            findings.append(finding)
            by_subject[finding.subject] += 1
            by_subject_topic[f"{finding.subject} :: {finding.topic}"] += 1
            for check in finding.checks:
                by_check[check] += 1

    return {
        "input_dir": str(input_dir),
        "totals": {
            "questions_scanned": total_questions,
            "questions_with_issues": len(findings),
        },
        "issues_by_type": dict(by_check.most_common()),
        "issues_by_subject": dict(by_subject.most_common()),
        "issues_by_subject_topic": dict(
            by_subject_topic.most_common()
        ),
        "findings": [f.as_dict() for f in findings],
    }


def main() -> None:
    parser = argparse.ArgumentParser(
        description="Find questions likely to be dropped at runtime."
    )
    parser.add_argument(
        "--input-dir",
        type=Path,
        default=DEFAULT_INPUT_DIR,
        help=f"Question JSON root directory (default: {DEFAULT_INPUT_DIR})",
    )
    parser.add_argument(
        "--output",
        type=Path,
        default=DEFAULT_OUTPUT_PATH,
        help=f"Output report path (default: {DEFAULT_OUTPUT_PATH})",
    )
    parser.add_argument(
        "--print-findings",
        action="store_true",
        help="Print per-question findings in terminal output.",
    )
    args = parser.parse_args()

    input_dir = (
        args.input_dir if args.input_dir.is_absolute() else (REPO_ROOT / args.input_dir)
    )
    output_path = args.output if args.output.is_absolute() else (REPO_ROOT / args.output)
    if not input_dir.exists():
        raise SystemExit(f"Input directory not found: {input_dir}")

    report = run_validation(input_dir)
    output_path.parent.mkdir(parents=True, exist_ok=True)
    output_path.write_text(json.dumps(report, indent=2), encoding="utf-8")

    print(f"Scanned questions: {report['totals']['questions_scanned']}")
    print(f"Questions with issues: {report['totals']['questions_with_issues']}")
    print("\nTop issue types:")
    for issue, count in list(report["issues_by_type"].items())[:10]:
        print(f"- {issue}: {count}")
    print(f"\nReport written to: {output_path}")

    if args.print_findings:
        print("\nFindings:")
        for finding in report["findings"]:
            checks = ", ".join(finding["checks"])
            print(
                f"- {finding['uuid']} | {finding['subject']} | "
                f"{finding['topic']} | {checks}"
            )


if __name__ == "__main__":
    main()
