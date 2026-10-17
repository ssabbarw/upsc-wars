#!/usr/bin/env python3
"""
Generate the Prelims Test Series (static, PYQ-mix and full-length mock shells).

The generator is deterministic (seeded) and reads question UUIDs from the same
SQLite DB the app ships, so UUIDs match exactly what the app resolves. It does
NOT write to Firebase: it writes one JSON file which
`functions/scripts/upload_test_series.js` uploads. Current-affairs tests and the
current-affairs slots of mock tests are filled later by the monthly Cloud
Function (they depend on the daily CA archive).

Usage:
    python3 tools/test_series/generate_series.py \
        --series-id prelims_2027 --launch-date 2026-10-17 \
        --prelims-date 2027-05-23

    # Reuse an already-built DB instead of building one into a temp file:
    python3 tools/test_series/generate_series.py --db /path/to/questions.db

Output: tools/test_series/out/<series-id>.json (gitignored).

Series shape (see docs/test_series_setup.md):
  - 38 static tests (50 Q): Polity/Economy/Environment/Geography/Modern History
    x6 and "Ancient + Medieval + Art & Culture" x8. Topic themed, ~10% PYQ.
  - 4 "Full Syllabus" static tests (50 Q): all subjects in Prelims proportion.
  - 6 free cross-year PYQ mix tests (50 Q).
  - 8 current-affairs test shells (50 Q, filled monthly) with 5 PYQ each.
  - 14 full-length mocks (100 Q): 55 static + 10 PYQ + 35 CA (CA filled later).
"""

from __future__ import annotations

import argparse
import json
import random
import sqlite3
import subprocess
import sys
import tempfile
from collections import defaultdict
from dataclasses import dataclass, field
from datetime import date, datetime, timedelta, timezone
from pathlib import Path
from typing import Any

PROJECT_ROOT = Path(__file__).resolve().parents[2]
OUT_DIR = Path(__file__).resolve().parent / "out"
IST = timezone(timedelta(hours=5, minutes=30))

# ---------------------------------------------------------------------------
# Series blueprint
# ---------------------------------------------------------------------------

STATIC_Q = 50
STATIC_PYQ_PER_TEST = 5  # 10%
STATIC_THEME_SHARE = 32  # of the 45 static questions, drawn from the theme topics
FULL_SYLLABUS_TESTS = 4  # whole-syllabus static tests (50 Q), listed under Subject tests
PYQ_MIX_Q = 50
PYQ_MIX_TESTS = 6
CA_TEST_Q = 50
CA_TEST_PYQ = 5
CA_TEST_PRIMARY = 30  # from the previous month (filled by the function)
FLT_Q = 100
FLT_STATIC = 55
FLT_PYQ = 10
FLT_CA = 35
MINUTES_PER_QUESTION = 1.2  # same pace as the real paper (100 Q in 120 min)

# bucket id -> (display name, db `subject` values, test count)
BUCKETS: dict[str, dict[str, Any]] = {
    "polity": {"name": "Polity", "subjects": ["Polity"], "tests": 6},
    "economy": {"name": "Economy", "subjects": ["Economy"], "tests": 6},
    "environment": {"name": "Environment", "subjects": ["Environment"], "tests": 6},
    "geography": {"name": "Geography", "subjects": ["Geography"], "tests": 6},
    "modern_history": {
        "name": "Modern History",
        "subjects": ["Modern History"],
        "tests": 6,
    },
    "history_culture": {
        "name": "Ancient, Medieval & Art and Culture",
        "subjects": ["Ancient History", "Medieval History", "Art and Culture"],
        "tests": 8,
        # themed tests per db subject, plus one mixed revision test
        "per_subject": {
            "Ancient History": 2,
            "Medieval History": 2,
            "Art and Culture": 3,
        },
        "mixed": 1,
    },
}

# PYQ `gs_subject` (as stored by build_question_db.py) -> series bucket / tag
PYQ_SUBJECT_TO_BUCKET = {
    "Polity": "polity",
    "Economy": "economy",
    "Economics": "economy",
    "Environment": "environment",
    "Geography": "geography",
    "Modern history": "modern_history",
    "Ancient history and culture": "history_culture",
    "प्राचीन इतिहास और संस्कृति": "history_culture",
    "History": "history_culture",
}
PYQ_CA_SUBJECTS = {"Current affairs"}

CA_UNLOCK_MONTHS_AFTER_LAUNCH = True  # CA tests unlock on the 1st of each month


# ---------------------------------------------------------------------------
# Data loading
# ---------------------------------------------------------------------------


@dataclass
class Q:
    uuid: str
    subject: str
    topic: str
    gs_subject: str
    source_kind: str
    source_year: int | None


def ensure_db(db_path: str | None) -> Path:
    if db_path:
        return Path(db_path).expanduser().resolve()
    tmp = Path(tempfile.gettempdir()) / "series_qdb.db"
    print(f"[INFO] Building question DB -> {tmp}")
    subprocess.run(
        [sys.executable, str(PROJECT_ROOT / "tools" / "build_question_db.py"), str(tmp)],
        check=True,
        stdout=subprocess.DEVNULL,
    )
    return tmp


def load_questions(db: Path) -> list[Q]:
    conn = sqlite3.connect(str(db))
    try:
        rows = conn.execute(
            """
            SELECT uuid, subject, COALESCE(topic, ''), COALESCE(gs_subject, ''),
                   source_kind, source_year
            FROM questions
            WHERE en_display_text IS NOT NULL AND en_display_text <> ''
              AND hi_display_text IS NOT NULL AND hi_display_text <> ''
            """
        ).fetchall()
    finally:
        conn.close()
    return [Q(r[0], r[1], r[2] or "General", r[3], r[4], r[5]) for r in rows]


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------


def largest_remainder(weights: dict[str, float], total: int) -> dict[str, int]:
    s = sum(weights.values())
    raw = {k: weights[k] / s * total for k in weights}
    out = {k: int(v) for k, v in raw.items()}
    rest = total - sum(out.values())
    for k in sorted(raw, key=lambda k: raw[k] - out[k], reverse=True)[:rest]:
        out[k] += 1
    return out


def balance_groups(topics: dict[str, int], n_groups: int) -> list[list[str]]:
    """Longest-processing-time partition so each group has a similar size."""
    groups: list[list[str]] = [[] for _ in range(n_groups)]
    sizes = [0] * n_groups
    for topic in sorted(topics, key=lambda t: (-topics[t], t)):
        i = min(range(n_groups), key=lambda j: sizes[j])
        groups[i].append(topic)
        sizes[i] += topics[topic]
    # Largest groups first so Test 1 is the broadest theme.
    order = sorted(range(n_groups), key=lambda j: -sizes[j])
    return [groups[i] for i in order]


def ist_midnight(d: date) -> str:
    return datetime(d.year, d.month, d.day, tzinfo=IST).isoformat()


def add_months(d: date, n: int) -> date:
    idx = d.year * 12 + (d.month - 1) + n
    return date(idx // 12, idx % 12 + 1, 1)


def month_key(d: date) -> str:
    return f"{d.year}-{d.month:02d}"


def duration(n_questions: int) -> int:
    return int(round(n_questions * MINUTES_PER_QUESTION / 5.0) * 5)


# ---------------------------------------------------------------------------
# Generator
# ---------------------------------------------------------------------------


@dataclass
class Generator:
    questions: list[Q]
    rng: random.Random
    launch: date
    prelims: date
    series_id: str
    used_static: set[str] = field(default_factory=set)
    pyq_use: dict[str, int] = field(default_factory=lambda: defaultdict(int))

    def __post_init__(self) -> None:
        self.static_by_bucket: dict[str, dict[str, dict[str, list[str]]]] = {}
        for bucket, cfg in BUCKETS.items():
            per_subject: dict[str, dict[str, list[str]]] = {}
            for subj in cfg["subjects"]:
                topics: dict[str, list[str]] = defaultdict(list)
                for q in self.questions:
                    if q.source_kind == "static" and q.subject == subj:
                        topics[q.topic].append(q.uuid)
                for lst in topics.values():
                    self.rng.shuffle(lst)
                per_subject[subj] = dict(topics)
            self.static_by_bucket[bucket] = per_subject

        self.pyqs = [q for q in self.questions if q.source_kind == "pyq"]
        self.pyq_by_uuid = {q.uuid: q for q in self.pyqs}
        self.pyq_bucket: dict[str, str | None] = {}
        for q in self.pyqs:
            if q.gs_subject in PYQ_SUBJECT_TO_BUCKET:
                self.pyq_bucket[q.uuid] = PYQ_SUBJECT_TO_BUCKET[q.gs_subject]
            elif q.gs_subject in PYQ_CA_SUBJECTS:
                self.pyq_bucket[q.uuid] = "ca"
            else:
                self.pyq_bucket[q.uuid] = None
        self.tests: list[dict[str, Any]] = []

    # -- picking ------------------------------------------------------------

    def _take_static(self, bucket: str, subjects: list[str], topics: list[str] | None,
                     n: int, exclude: set[str]) -> list[str]:
        """Take n unused static UUIDs from the given subjects/topics."""
        pool: list[str] = []
        for subj in subjects:
            for topic, uuids in self.static_by_bucket[bucket][subj].items():
                if topics is not None and topic not in topics:
                    continue
                pool.extend(u for u in uuids if u not in self.used_static and u not in exclude)
        self.rng.shuffle(pool)
        picked = pool[:n]
        self.used_static.update(picked)
        return picked

    def _pick_pyq(self, n: int, in_test: set[str], bucket: str | None = None,
                  balance_years: bool = False) -> list[Q]:
        """Least-used PYQs first; never the same PYQ twice within one test."""
        cands = [
            q for q in self.pyqs
            if q.uuid not in in_test and (bucket is None or self.pyq_bucket[q.uuid] == bucket)
        ]
        picked: list[Q] = []
        if balance_years:
            by_year: dict[int, list[Q]] = defaultdict(list)
            for q in cands:
                by_year[q.source_year or 0].append(q)
            for lst in by_year.values():
                self.rng.shuffle(lst)
                lst.sort(key=lambda q: self.pyq_use[q.uuid])
            years = sorted(by_year)
            while len(picked) < n and any(by_year[y] for y in years):
                for y in years:
                    if by_year[y] and len(picked) < n:
                        picked.append(by_year[y].pop(0))
        else:
            self.rng.shuffle(cands)
            cands.sort(key=lambda q: self.pyq_use[q.uuid])
            picked = cands[:n]
        for q in picked:
            self.pyq_use[q.uuid] += 1
            in_test.add(q.uuid)
        return picked

    @staticmethod
    def _s(uuid: str) -> dict[str, Any]:
        return {"uuid": uuid, "kind": "static"}

    @staticmethod
    def _p(q: Q) -> dict[str, Any]:
        return {"uuid": q.uuid, "kind": "pyq", "pyqYear": q.source_year}

    # -- test construction --------------------------------------------------

    def add_test(self, **kw: Any) -> None:
        self.tests.append(kw)

    def build_flt_reserve(self, flt_count: int) -> dict[str, list[str]]:
        """Reserve FLT static questions up-front so topic tests never reuse them."""
        weights = defaultdict(float)
        for q in self.pyqs:
            b = self.pyq_bucket[q.uuid]
            if b in BUCKETS:
                weights[b] += 1
        alloc = largest_remainder(dict(weights), FLT_STATIC)
        print(f"[INFO] FLT static split per paper (from PYQ weightage): {alloc}")
        self.flt_alloc = alloc
        reserve: dict[str, list[str]] = {}
        for bucket, per_paper in alloc.items():
            cfg = BUCKETS[bucket]
            reserve[bucket] = self._take_static(
                bucket, cfg["subjects"], None, per_paper * flt_count, set()
            )
        return reserve

    def build_static_tests(self) -> None:
        for bucket, cfg in BUCKETS.items():
            specs: list[dict[str, Any]] = []  # each: subjects, theme_topics|None
            if "per_subject" in cfg:
                for subj, k in cfg["per_subject"].items():
                    topics = {t: len(u) for t, u in self.static_by_bucket[bucket][subj].items()}
                    for grp in balance_groups(topics, k):
                        specs.append({"subjects": [subj], "topics": grp})
                for _ in range(cfg.get("mixed", 0)):
                    specs.append({"subjects": cfg["subjects"], "topics": None})
            else:
                subj = cfg["subjects"][0]
                topics = {t: len(u) for t, u in self.static_by_bucket[bucket][subj].items()}
                for grp in balance_groups(topics, cfg["tests"]):
                    specs.append({"subjects": cfg["subjects"], "topics": grp})

            for i, spec in enumerate(specs, start=1):
                n_static = STATIC_Q - STATIC_PYQ_PER_TEST
                picked: list[str] = []
                if spec["topics"] is not None:
                    picked += self._take_static(bucket, spec["subjects"], spec["topics"],
                                                min(STATIC_THEME_SHARE, n_static), set())
                picked += self._take_static(bucket, cfg["subjects"], None,
                                            n_static - len(picked), set(picked))
                in_test: set[str] = set()
                pyqs = self._pick_pyq(STATIC_PYQ_PER_TEST, in_test, bucket=bucket)
                if len(pyqs) < STATIC_PYQ_PER_TEST:
                    pyqs += self._pick_pyq(STATIC_PYQ_PER_TEST - len(pyqs), in_test)
                items = [self._s(u) for u in picked] + [self._p(q) for q in pyqs]
                self.rng.shuffle(items)

                theme_topics = spec["topics"] or []
                theme_label = " · ".join(theme_topics[:2]) if theme_topics else "Mixed revision"
                if theme_topics and len(theme_topics) > 2:
                    theme_label += " & more"
                self.add_test(
                    id=f"static_{bucket}_{i:02d}",
                    kind="static",
                    bucket=bucket,
                    title=f"{cfg['name']} Test {i}",
                    theme=theme_label,
                    themeTopics=theme_topics,
                    index=i,
                    isFree=(i == 1),
                    unlockAt=ist_midnight(self.launch),
                    questionCount=STATIC_Q,
                    status="ready",
                    questions=items,
                )

    def build_full_syllabus_tests(self) -> None:
        """Whole-syllabus static tests: every subject in one 50-question paper.

        Built last so earlier tests (and an already-uploaded series) are not
        affected: it only draws static questions nobody else has used.
        Subject split follows the PYQ weightage used for the mocks.
        """
        n_static = STATIC_Q - STATIC_PYQ_PER_TEST
        split = largest_remainder(dict(self.flt_alloc), n_static)
        for i in range(1, FULL_SYLLABUS_TESTS + 1):
            picked: list[str] = []
            for bucket, count in split.items():
                picked += self._take_static(
                    bucket, BUCKETS[bucket]["subjects"], None, count, set(picked)
                )
            in_test: set[str] = set()
            pyqs = self._pick_pyq(STATIC_PYQ_PER_TEST, in_test, balance_years=True)
            items = [self._s(u) for u in picked] + [self._p(q) for q in pyqs]
            self.rng.shuffle(items)
            self.add_test(
                id=f"static_full_syllabus_{i:02d}",
                kind="static",
                bucket="full_syllabus",
                title=f"Full Syllabus Test {i}",
                theme="All subjects, Prelims proportions",
                themeTopics=[],
                index=i,
                isFree=False,
                unlockAt=ist_midnight(self.launch),
                questionCount=STATIC_Q,
                status="ready",
                questions=items,
            )

    def build_ca_shells(self) -> None:
        first_unlock = date(self.launch.year, self.launch.month, 1)
        last_month = date(self.prelims.year, self.prelims.month, 1)
        unlock = first_unlock
        i = 1
        while unlock <= last_month:
            primary = add_months(unlock, -1)
            earlier = [add_months(unlock, -3), add_months(unlock, -2)]
            in_test: set[str] = set()
            pyqs = self._pick_pyq(CA_TEST_PYQ, in_test, bucket="ca")
            if len(pyqs) < CA_TEST_PYQ:
                pyqs += self._pick_pyq(CA_TEST_PYQ - len(pyqs), in_test)
            self.add_test(
                id=f"ca_{month_key(unlock).replace('-', '_')}",
                kind="ca",
                bucket="current_affairs",
                title=f"Current Affairs Test {i}",
                theme=None,
                themeTopics=[],
                index=i,
                isFree=(i == 1),
                unlockAt=ist_midnight(max(unlock, self.launch)),
                questionCount=CA_TEST_Q,
                status="pending_ca",
                caSlots=CA_TEST_Q - CA_TEST_PYQ,
                caPrimarySlots=CA_TEST_PRIMARY,
                caWindow={
                    "primaryMonth": month_key(primary),
                    "earlierMonths": [month_key(m) for m in earlier],
                },
                questions=[self._p(q) for q in pyqs],
            )
            unlock = add_months(unlock, 1)
            i += 1

    def flt_unlock_dates(self) -> list[date]:
        # 1 now, then the 1st of each month until March, then weekly-ish in the
        # last two months before Prelims (the last one at least 6 days before).
        prelims_month = date(self.prelims.year, self.prelims.month, 1)
        dates = [self.launch]
        d = add_months(self.launch, 1)
        end_monthly = add_months(prelims_month, -2)
        while d <= end_monthly:
            dates.append(d)
            d = add_months(d, 1)
        # Four mocks in each of the last two months, none later than 6 days
        # before the exam so aspirants can still review.
        last_allowed = self.prelims - timedelta(days=6)
        for first, offsets in (
            (add_months(prelims_month, -1), [0, 7, 14, 21]),
            (prelims_month, [0, 5, 10, 15]),
        ):
            for off in offsets:
                dd = first + timedelta(days=off)
                if self.launch < dd <= last_allowed:
                    dates.append(dd)
        return sorted(set(dates))

    def build_flts(self, reserve: dict[str, list[str]]) -> None:
        dates = self.flt_unlock_dates()
        n = len(dates)
        cursors = {b: 0 for b in reserve}
        for i, d in enumerate(dates, start=1):
            items: list[dict[str, Any]] = []
            for bucket, per_paper in self.flt_alloc.items():
                start = cursors[bucket]
                chunk = reserve[bucket][start:start + per_paper]
                cursors[bucket] += per_paper
                items += [self._s(u) for u in chunk]
            in_test = set()
            pyqs = self._pick_pyq(FLT_PYQ, in_test)
            items += [self._p(q) for q in pyqs]
            self.rng.shuffle(items)
            self.add_test(
                id=f"flt_{i:02d}",
                kind="flt",
                bucket="mock",
                title=f"Full Length Mock {i}",
                theme=None,
                themeTopics=[],
                index=i,
                isFree=(i == 1),
                unlockAt=ist_midnight(d),
                questionCount=FLT_Q,
                status="pending_ca",
                caSlots=FLT_CA,
                questions=items,
            )
        print(f"[INFO] FLT unlock dates ({n}): {[x.isoformat() for x in dates]}")

    def build_pyq_mix(self) -> None:
        for i in range(1, PYQ_MIX_TESTS + 1):
            in_test: set[str] = set()
            pyqs = self._pick_pyq(PYQ_MIX_Q, in_test, balance_years=True)
            items = [self._p(q) for q in pyqs]
            self.rng.shuffle(items)
            self.add_test(
                id=f"pyq_mix_{i:02d}",
                kind="pyq_mix",
                bucket="pyq",
                title=f"PYQ Mix Test {i}",
                theme="Previous years' questions, all years",
                themeTopics=[],
                index=i,
                isFree=True,
                unlockAt=ist_midnight(self.launch),
                questionCount=len(items),
                status="ready",
                questions=items,
            )


def finalize(tests: list[dict[str, Any]]) -> None:
    for t in tests:
        t["durationMins"] = duration(t["questionCount"])


def validate(tests: list[dict[str, Any]]) -> None:
    ids = [t["id"] for t in tests]
    assert len(ids) == len(set(ids)), "duplicate test ids"
    static_seen: dict[str, str] = {}
    for t in tests:
        uuids = [q["uuid"] for q in t["questions"]]
        assert len(uuids) == len(set(uuids)), f"duplicate question inside {t['id']}"
        if t["status"] == "ready":
            assert len(uuids) == t["questionCount"], f"{t['id']} has {len(uuids)} questions"
        for q in t["questions"]:
            if q["kind"] == "static":
                other = static_seen.get(q["uuid"])
                assert other is None, f"static {q['uuid']} reused in {t['id']} and {other}"
                static_seen[q["uuid"]] = t["id"]


def main() -> None:
    ap = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--series-id", default="prelims_2027")
    ap.add_argument("--year", type=int, default=2027)
    ap.add_argument("--launch-date", default=date.today().isoformat(), help="YYYY-MM-DD (IST)")
    ap.add_argument("--prelims-date", default="2027-05-23", help="YYYY-MM-DD")
    ap.add_argument("--product-id", default=None, help="default: <series-id>_pass")
    ap.add_argument("--db", default=None, help="Built questions SQLite DB (default: build a temp one)")
    ap.add_argument("--seed", type=int, default=2027)
    args = ap.parse_args()

    launch = date.fromisoformat(args.launch_date)
    prelims = date.fromisoformat(args.prelims_date)
    rng = random.Random(args.seed)

    db = ensure_db(args.db)
    questions = load_questions(db)
    n_static = sum(1 for q in questions if q.source_kind == "static")
    n_pyq = sum(1 for q in questions if q.source_kind == "pyq")
    print(f"[INFO] Eligible (bilingual) questions: static={n_static}, pyq={n_pyq}")

    gen = Generator(questions, rng, launch, prelims, args.series_id)

    # Order matters: FLT static reserve first, then themed tests, then PYQ fills.
    n_flt = len(gen.flt_unlock_dates())
    reserve = gen.build_flt_reserve(n_flt)
    gen.build_static_tests()
    gen.build_ca_shells()
    gen.build_flts(reserve)
    gen.build_pyq_mix()
    gen.build_full_syllabus_tests()  # last: keeps every earlier test unchanged
    finalize(gen.tests)
    validate(gen.tests)

    product_id = args.product_id or f"{args.series_id}_pass"
    by_kind: dict[str, int] = defaultdict(int)
    for t in gen.tests:
        by_kind[t["kind"]] += 1
    free = sum(1 for t in gen.tests if t["isFree"])

    pyq_reuse = sum(1 for v in gen.pyq_use.values() if v > 1)
    series = {
        "id": args.series_id,
        "title": f"Prelims {args.year} Test Series",
        "titleHi": f"प्रीलिम्स {args.year} टेस्ट सीरीज़",
        "year": args.year,
        "launchAt": ist_midnight(launch),
        "prelimsDate": prelims.isoformat(),
        "productId": product_id,
        "entitlementId": args.series_id,
        "testCount": len(gen.tests),
        "freeTestCount": free,
        "counts": dict(by_kind),
        "schemaVersion": 1,
    }
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    out = OUT_DIR / f"{args.series_id}.json"
    out.write_text(json.dumps({"series": series, "tests": gen.tests}, ensure_ascii=False, indent=1), encoding="utf-8")

    print(f"[DONE] {len(gen.tests)} tests ({dict(by_kind)}), {free} free -> {out}")
    print(f"[INFO] PYQs used more than once across the series: {pyq_reuse} of {len(gen.pyqs)}")


if __name__ == "__main__":
    main()
