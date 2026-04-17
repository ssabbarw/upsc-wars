#!/usr/bin/env python3
"""
Analyze trap types across UPSC question bank JSON files.
Usage: python analyze_traps.py <folder_path>
Output: trap_analysis.json and trap_analysis.csv
"""

import json
import csv
import sys
import os
from collections import defaultdict
from pathlib import Path


def load_all_questions(folder_path):
    questions = []
    folder = Path(folder_path)
    json_files = list(folder.rglob("*.json"))

    if not json_files:
        print(f"No JSON files found in {folder_path}")
        sys.exit(1)

    print(f"Found {len(json_files)} JSON files...")

    for f in json_files:
        try:
            with open(f, "r", encoding="utf-8") as fh:
                data = json.load(fh)
                if isinstance(data, list):
                    questions.extend(data)
                elif isinstance(data, dict):
                    questions.append(data)
        except Exception as e:
            print(f"  Skipping {f.name}: {e}")

    print(f"Loaded {len(questions)} questions total.\n")
    return questions


def analyze(questions):
    # Raw counts
    trap_counts = defaultdict(int)
    trap_by_subject = defaultdict(lambda: defaultdict(int))
    trap_by_topic = defaultdict(lambda: defaultdict(int))
    trap_by_question_type = defaultdict(lambda: defaultdict(int))
    missing_trap = []

    for q in questions:
        uuid = q.get("uuid", "unknown")
        meta = q.get("meta", {})
        shared = q.get("shared", {})

        subject = meta.get("subject", "Unknown")
        topic = meta.get("topic", "Unknown")
        sub_topic = meta.get("sub_topic", "Unknown")
        question_type = shared.get("question_type", "Unknown")
        trap_type = (shared.get("trap_type") or "").strip().lower()

        if not trap_type:
            missing_trap.append({
                "uuid": uuid,
                "subject": subject,
                "topic": topic,
                "sub_topic": sub_topic,
            })
            continue

        trap_counts[trap_type] += 1
        trap_by_subject[trap_type][subject] += 1
        trap_by_topic[trap_type][f"{subject} > {topic}"] += 1
        trap_by_question_type[trap_type][question_type] += 1

    return {
        "trap_counts": dict(sorted(trap_counts.items(), key=lambda x: -x[1])),
        "trap_by_subject": {k: dict(sorted(v.items(), key=lambda x: -x[1])) for k, v in trap_by_subject.items()},
        "trap_by_topic": {k: dict(sorted(v.items(), key=lambda x: -x[1])) for k, v in trap_by_topic.items()},
        "trap_by_question_type": {k: dict(v) for k, v in trap_by_question_type.items()},
        "missing_trap_count": len(missing_trap),
        "missing_trap_examples": missing_trap[:10],  # first 10 only
        "total_questions": len(questions),
    }


def print_summary(analysis):
    total = analysis["total_questions"]
    print("=" * 60)
    print("TRAP TYPE SUMMARY")
    print("=" * 60)
    print(f"{'Trap Type':<30} {'Count':>6}  {'% of Bank':>10}")
    print("-" * 60)
    for trap, count in analysis["trap_counts"].items():
        pct = (count / total) * 100
        print(f"{trap:<30} {count:>6}  {pct:>9.1f}%")

    print(f"\nTotal questions: {total}")
    print(f"Questions with no trap_type: {analysis['missing_trap_count']}")

    print("\n" + "=" * 60)
    print("TRAP TYPE BY SUBJECT")
    print("=" * 60)
    for trap, subjects in analysis["trap_by_subject"].items():
        print(f"\n{trap.upper()}")
        for subject, count in subjects.items():
            print(f"  {subject:<40} {count}")

    print("\n" + "=" * 60)
    print("TRAP TYPE BY QUESTION TYPE")
    print("=" * 60)
    for trap, qtypes in analysis["trap_by_question_type"].items():
        print(f"\n{trap.upper()}")
        for qtype, count in qtypes.items():
            print(f"  {qtype:<40} {count}")


def save_outputs(analysis, output_dir):
    # Save full JSON
    json_path = Path(output_dir) / "trap_analysis.json"
    with open(json_path, "w", encoding="utf-8") as f:
        json.dump(analysis, f, indent=2, ensure_ascii=False)
    print(f"\nFull analysis saved to: {json_path}")

    # Save flat CSV for easy scanning
    csv_path = Path(output_dir) / "trap_analysis.csv"
    with open(csv_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerow(["trap_type", "total_count", "subject", "subject_count"])
        for trap, subjects in analysis["trap_by_subject"].items():
            for subject, count in subjects.items():
                writer.writerow([trap, analysis["trap_counts"][trap], subject, count])
    print(f"CSV saved to: {csv_path}")


def main():
    if len(sys.argv) < 2:
        print("Usage: python analyze_traps.py <folder_with_json_files>")
        print("Output files will be saved in the same folder.")
        sys.exit(1)

    folder = sys.argv[1]
    if not os.path.isdir(folder):
        print(f"Error: {folder} is not a valid directory.")
        sys.exit(1)

    questions = load_all_questions(folder)
    analysis = analyze(questions)
    print_summary(analysis)
    save_outputs(analysis, folder)


if __name__ == "__main__":
    main()