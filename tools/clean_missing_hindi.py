#!/usr/bin/env python3
"""
Remove questions that lack required Hindi content (display text or final explanation)
and are not table questions.

Usage:
    python tools/clean_missing_hindi.py

Rules:
- Walks assets/final_cleaned_questions/<subject>/*.json.
- For each question object:
    - Reads shared.has_table, hi.display_text, hi.final_explanation.
    - If has_table is FALSE (or missing/falsey) AND either
        * hi.display_text is missing/null/empty, OR
        * hi.final_explanation is missing/null/empty,
      then that question is dropped.
- Files are rewritten in-place with only the kept questions.
- Prints per-file and total removal counts.
"""

import json
from pathlib import Path
from typing import Any


PROJECT_ROOT = Path(__file__).resolve().parents[1]
QUESTIONS_ROOT = PROJECT_ROOT / "assets" / "final_cleaned_questions"


def _is_empty_str(value: Any) -> bool:
    return value is None or (isinstance(value, str) and value.strip() == "")


def main() -> None:
    if not QUESTIONS_ROOT.exists():
        print(f"[ERROR] Directory not found: {QUESTIONS_ROOT}")
        raise SystemExit(1)

    total_removed = 0
    total_kept = 0
    total_files = 0

    for subject_dir in sorted(p for p in QUESTIONS_ROOT.iterdir() if p.is_dir()):
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

            if not isinstance(data, list):
                print(f"[WARN] Skipping non-list JSON {jf}")
                continue

            kept: list[dict[str, Any]] = []
            removed_here = 0

            for obj in data:
                if not isinstance(obj, dict):
                    # Malformed item, keep as-is to avoid data loss.
                    kept.append(obj)
                    continue

                shared = obj.get("shared") or {}
                hi = obj.get("hi") or {}

                has_table = bool(shared.get("has_table"))
                hi_display = hi.get("display_text")
                hi_final_expl = hi.get("final_explanation")

                # Removal condition for non-table questions:
                # missing/empty Hindi display text OR Hindi final explanation.
                if not has_table and (
                    _is_empty_str(hi_display) or _is_empty_str(hi_final_expl)
                ):
                    removed_here += 1
                    continue

                kept.append(obj)

            if removed_here > 0:
                with jf.open("w", encoding="utf-8") as f:
                    json.dump(kept, f, ensure_ascii=False, indent=2)

            total_removed += removed_here
            total_kept += len(kept)

            if removed_here > 0:
                print(
                    f"[INFO] {jf}: removed {removed_here} question(s), "
                    f"kept {len(kept)}"
                )

    print(
        f"[DONE] Processed {total_files} file(s). "
        f"Removed {total_removed} question(s), kept {total_kept}."
    )


if __name__ == "__main__":
    main()

