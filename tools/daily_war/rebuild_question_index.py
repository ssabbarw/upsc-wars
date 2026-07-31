#!/usr/bin/env python3
"""Rebuild functions/daily_war/question_index.json from assets/final_cleaned_questions."""
from __future__ import annotations
import json, glob, os
from collections import defaultdict
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "functions/daily_war/question_index.json"

def main() -> None:
    index: dict[str, list] = defaultdict(list)
    for subj_dir in glob.glob(str(ROOT / "assets/final_cleaned_questions/*")):
        subj = os.path.basename(subj_dir)
        for f in glob.glob(subj_dir + "/*.json"):
            d = json.load(open(f))
            items = d if isinstance(d, list) else d.get("questions", [d])
            for q in items:
                meta = q.get("meta") or {}
                topic = meta.get("topic")
                if not topic:
                    continue
                uuid = q.get("uuid")
                correct = (q.get("shared") or {}).get("correct_option")
                if not uuid or not correct:
                    continue
                index[f"{subj}::{topic}"].append(
                    {"u": uuid, "c": str(correct).lower()[:1], "st": meta.get("sub_topic") or ""}
                )
    OUT.write_text(json.dumps(index, separators=(",", ":")))
    print(f"wrote {OUT} keys={len(index)} bytes={OUT.stat().st_size}")

if __name__ == "__main__":
    main()
