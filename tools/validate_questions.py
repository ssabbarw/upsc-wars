#!/usr/bin/env python3
"""
Validate cleaned question JSON files against the SQLite schema constraints.

Usage:
    python tools/validate_questions.py

This script walks assets/final_cleaned_questions and checks that each
question can safely be inserted into the `questions` table defined in
lib/schema.md / build_question_db.py, i.e. that:

- Required top-level keys exist (uuid, meta, shared, en, hi).
- Required meta fields exist and are non-empty (subject, topic, sub_topic).
- Required shared fields exist and are non-empty:
    correct_option, question_type, trap_type, concept_anchor.
- meta.concepts_used exists (list, may be empty but not null).
- en.display_text and hi.display_text exist and are non-empty strings.

It prints a summary at the end and exits with status 1 if any violations
are found, so you can wire it into CI or pre-build checks.
"""

import json
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Optional


PROJECT_ROOT = Path(__file__).resolve().parents[1]
QUESTIONS_ROOT = PROJECT_ROOT / "assets" / "final_cleaned_questions"


@dataclass
class ValidationError:
    file: Path
    index: int  # index within the JSON list
    uuid: Optional[str]
    message: str


def _non_empty_str(value: Any) -> bool:
    return isinstance(value, str) and value.strip() != ""


def validate_question_obj(
    file_path: Path,
    idx: int,
    obj: dict[str, Any],
) -> list[ValidationError]:
    errors: list[ValidationError] = []

    uuid = obj.get("uuid")
    if not _non_empty_str(uuid):
        errors.append(
            ValidationError(
                file=file_path,
                index=idx,
                uuid=None,
                message="Missing or empty 'uuid'",
            )
        )

    def err(msg: str) -> None:
        errors.append(
            ValidationError(
                file=file_path,
                index=idx,
                uuid=uuid if isinstance(uuid, str) else None,
                message=msg,
            )
        )

    meta = obj.get("meta")
    if not isinstance(meta, dict):
        err("Missing or invalid 'meta' object")
        return errors

    shared = obj.get("shared")
    if not isinstance(shared, dict):
        err("Missing or invalid 'shared' object")
        return errors

    en = obj.get("en")
    if not isinstance(en, dict):
        err("Missing or invalid 'en' object")
        return errors

    hi = obj.get("hi")
    if not isinstance(hi, dict):
        err("Missing or invalid 'hi' object")
        return errors

    # Meta fields: subject, topic, sub_topic (TEXT NOT NULL)
    for key in ("subject", "topic", "sub_topic"):
        value = meta.get(key)
        if not _non_empty_str(value):
            err(f"meta.{key} is missing or empty")

    # concepts_used: JSON array stored as TEXT NOT NULL
    concepts_used = meta.get("concepts_used")
    if concepts_used is None:
        err("meta.concepts_used is missing (must be a list, can be empty)")
    elif not isinstance(concepts_used, list):
        err(f"meta.concepts_used must be a list, got {type(concepts_used).__name__}")

    # Shared fields for questions table
    # Mandatory: correct_option, question_type, concept_anchor
    for key in ("correct_option", "question_type", "concept_anchor"):
        value = shared.get(key)
        if not _non_empty_str(value):
            err(f"shared.{key} is missing or empty")
    # Optional: trap_type may be missing or empty

    # has_table: stored as INTEGER NOT NULL DEFAULT 0 (bool-like)
    has_table = shared.get("has_table")
    if has_table is None:
        err("shared.has_table is missing (expected bool)")

    is_table_question = bool(has_table)

    # Display text vs. table_data rules:
    # - If has_table is FALSE: display_text must be non-empty TEXT for both en/hi.
    # - If has_table is TRUE: display_text may be null/empty, but table_data must be
    #   present and structurally valid (header_text, footer_text, columns, rows).
    if not is_table_question:
        if not _non_empty_str(en.get("display_text")):
            err("en.display_text is missing or empty (TEXT NOT NULL when has_table=false)")
        if not _non_empty_str(hi.get("display_text")):
            err("hi.display_text is missing or empty (TEXT NOT NULL when has_table=false)")
    else:
        # Validate en.table_data
        en_table = en.get("table_data")
        if not isinstance(en_table, dict):
            err("en.table_data must be an object when has_table=true")
        else:
            if not _non_empty_str(en_table.get("header_text")):
                err("en.table_data.header_text is missing or empty")
            if not _non_empty_str(en_table.get("footer_text")):
                err("en.table_data.footer_text is missing or empty")
            cols = en_table.get("columns")
            rows = en_table.get("rows")
            if not isinstance(cols, list) or not cols:
                err("en.table_data.columns must be a non-empty list")
            if not isinstance(rows, list) or not rows:
                err("en.table_data.rows must be a non-empty list of rows")
            if isinstance(cols, list) and isinstance(rows, list) and cols and rows:
                expected_len = len(cols)
                for r in rows:
                    if not isinstance(r, list) or len(r) != expected_len:
                        err("en.table_data.rows contain a row with wrong length or non-list")
                        break

        # Validate hi.table_data
        hi_table = hi.get("table_data")
        if not isinstance(hi_table, dict):
            err("hi.table_data must be an object when has_table=true")
        else:
            if not _non_empty_str(hi_table.get("header_text")):
                err("hi.table_data.header_text is missing or empty")
            if not _non_empty_str(hi_table.get("footer_text")):
                err("hi.table_data.footer_text is missing or empty")
            cols = hi_table.get("columns")
            rows = hi_table.get("rows")
            if not isinstance(cols, list) or not cols:
                err("hi.table_data.columns must be a non-empty list")
            if not isinstance(rows, list) or not rows:
                err("hi.table_data.rows must be a non-empty list of rows")
            if isinstance(cols, list) and isinstance(rows, list) and cols and rows:
                expected_len = len(cols)
                for r in rows:
                    if not isinstance(r, list) or len(r) != expected_len:
                        err("hi.table_data.rows contain a row with wrong length or non-list")
                        break

    # Explanations: final_explanation is required for both languages.
    if not _non_empty_str(en.get("final_explanation")):
        err("en.final_explanation is missing or empty")
    if not _non_empty_str(hi.get("final_explanation")):
        err("hi.final_explanation is missing or empty")

    return errors


def validate_file(path: Path) -> list[ValidationError]:
    errors: list[ValidationError] = []
    try:
        with path.open("r", encoding="utf-8") as f:
            data = json.load(f)
    except Exception as exc:  # pragma: no cover - defensive
        errors.append(
            ValidationError(
                file=path,
                index=-1,
                uuid=None,
                message=f"Failed to parse JSON: {exc}",
            )
        )
        return errors

    if not isinstance(data, list):
        errors.append(
            ValidationError(
                file=path,
                index=-1,
                uuid=None,
                message=f"Top-level JSON must be a list, got {type(data).__name__}",
            )
        )
        return errors

    for idx, item in enumerate(data):
        if not isinstance(item, dict):
            errors.append(
                ValidationError(
                    file=path,
                    index=idx,
                    uuid=None,
                    message=f"Item at index {idx} is not an object: {type(item).__name__}",
                )
            )
            continue
        errors.extend(validate_question_obj(path, idx, item))

    return errors


def main() -> None:
    if not QUESTIONS_ROOT.exists():
        print(f"[ERROR] Directory not found: {QUESTIONS_ROOT}")
        raise SystemExit(1)

    all_errors: list[ValidationError] = []
    total_questions = 0
    total_files = 0

    for subject_dir in sorted(p for p in QUESTIONS_ROOT.iterdir() if p.is_dir()):
        json_files = sorted(subject_dir.glob("*.json"))
        if not json_files:
            print(f"[WARN] Subject '{subject_dir.name}': no JSON files found")
            continue

        for jf in json_files:
            total_files += 1
            file_errors = validate_file(jf)
            if not file_errors:
                # Count questions by re-reading as list length; cheap vs. plumbing length through.
                with jf.open("r", encoding="utf-8") as f:
                    data = json.load(f)
                if isinstance(data, list):
                    total_questions += len(data)
            all_errors.extend(file_errors)

    if all_errors:
        print("\n[VALIDATION FAILED]")
        for e in all_errors:
            idx_info = f"index {e.index}" if e.index >= 0 else "file-level"
            uuid_info = f", uuid={e.uuid}" if e.uuid else ""
            print(f"- {e.file} ({idx_info}{uuid_info}): {e.message}")
        print(
            f"\nChecked {total_files} files; "
            f"found {len(all_errors)} error(s)."
        )
        raise SystemExit(1)

    print(
        f"[VALIDATION OK] Checked {total_files} files, "
        f"total questions: {total_questions}, no schema-constraint violations."
    )


if __name__ == "__main__":
    main()

