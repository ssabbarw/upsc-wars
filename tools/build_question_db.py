#!/usr/bin/env python3
"""
Build a pre-populated SQLite database for the UPSC Wars app.

Usage:
    python tools/build_question_db.py /absolute/path/to/upsc_wars_questions.db

This script:
- Creates a new SQLite file at the given path (overwriting any existing file).
- Creates ALL tables described in lib/schema.md (question bank + user state).
- Populates the questions table from JSON files under assets/final_cleaned_questions/.
- Prints per-subject and total question counts.

This script fully populates questions, explanations, and question_tables.
"""

import argparse
import json
import sqlite3
import sys
from pathlib import Path
from typing import Iterable, Mapping, Any


def _as_non_null_text(value: Any) -> str:
    if value is None:
        return ""
    return str(value)


def verify_built_db(conn: sqlite3.Connection) -> None:
    """Run post-build integrity checks and print results."""
    cur = conn.cursor()

    required_tables = {
        "questions",
        "question_tables",
        "explanations",
        "sessions",
        "attempts",
        "bookmarks",
        "revision_queue",
        "user_topic_stats",
        "topic_translations",
    }
    cur.execute("SELECT name FROM sqlite_master WHERE type='table';")
    existing_tables = {row[0] for row in cur.fetchall()}
    missing_tables = sorted(required_tables - existing_tables)
    if missing_tables:
        raise RuntimeError(f"Missing required tables: {missing_tables}")

    cur.execute("PRAGMA table_info(questions);")
    question_cols = {row[1] for row in cur.fetchall()}
    forbidden_cols = {"subject_question_number", "overall_question_number"}
    still_present = sorted(question_cols & forbidden_cols)
    if still_present:
        raise RuntimeError(f"Unexpected columns still present in questions: {still_present}")

    cur.execute("PRAGMA table_info(question_tables);")
    question_table_cols = {row[1] for row in cur.fetchall()}
    expected_qt_cols = {
        "question_uuid",
        "en_header_text",
        "en_footer_text",
        "en_columns",
        "en_rows",
        "hi_header_text",
        "hi_footer_text",
        "hi_columns",
        "hi_rows",
    }
    missing_qt_cols = sorted(expected_qt_cols - question_table_cols)
    if missing_qt_cols:
        raise RuntimeError(f"Missing question_tables columns: {missing_qt_cols}")

    cur.execute("SELECT COUNT(*) FROM questions;")
    questions_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM explanations;")
    explanations_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM question_tables;")
    question_tables_count = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM questions WHERE has_table = 1;")
    has_table_count = cur.fetchone()[0]
    if question_tables_count != has_table_count:
        raise RuntimeError(
            "Mismatch between questions.has_table=1 and question_tables rows: "
            f"{has_table_count} vs {question_tables_count}"
        )

    cur.execute(
        """
        SELECT COUNT(*)
        FROM explanations
        WHERE strong_distractor IS NULL
           OR elimination_logic IS NULL
           OR upsc_trap_explanation IS NULL
           OR final_explanation IS NULL
        """
    )
    explanation_required_nulls = cur.fetchone()[0]
    if explanation_required_nulls > 0:
        raise RuntimeError(
            "Found NULL values in required explanation fields: "
            f"{explanation_required_nulls}"
        )

    cur.execute(
        """
        SELECT COUNT(*)
        FROM question_tables
        WHERE en_columns IS NULL
           OR en_rows IS NULL
           OR hi_columns IS NULL
           OR hi_rows IS NULL
        """
    )
    table_required_nulls = cur.fetchone()[0]
    if table_required_nulls > 0:
        raise RuntimeError(
            "Found NULL values in required table fields: "
            f"{table_required_nulls}"
        )

    cur.execute(
        """
        SELECT COUNT(*)
        FROM questions q
        LEFT JOIN explanations e ON e.question_uuid = q.uuid
        GROUP BY q.uuid
        HAVING COUNT(e.id) <> 2
        """
    )
    bad_explanation_links = len(cur.fetchall())
    if bad_explanation_links > 0:
        raise RuntimeError(
            "Questions without exactly 2 explanation rows (en+hi): "
            f"{bad_explanation_links}"
        )

    cur.execute("PRAGMA user_version;")
    user_version = cur.fetchone()[0]

    print("[VERIFY] OK")
    print(f"[VERIFY] questions={questions_count}")
    print(f"[VERIFY] explanations={explanations_count}")
    print(f"[VERIFY] question_tables={question_tables_count}")
    print(f"[VERIFY] questions_has_table_1={has_table_count}")
    print(f"[VERIFY] user_version={user_version}")


def create_schema(conn: sqlite3.Connection) -> None:
    """Create all tables and indexes matching lib/schema.md."""
    cur = conn.cursor()
    cur.execute("PRAGMA foreign_keys = ON;")
    # Keep SQLite's user_version in sync with Drift's schemaVersion (1).
    cur.execute("PRAGMA user_version = 1;")

    cur.executescript(
        """
        ------------------------------------------------------------------
        -- Core question bank
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS questions (
            uuid                      TEXT PRIMARY KEY,
            subject                   TEXT NOT NULL,
            topic                     TEXT NOT NULL,
            sub_topic                 TEXT NOT NULL,
            question_type             TEXT NOT NULL,
            -- Optional: some questions may not have a specific trap type.
            trap_type                 TEXT,
            correct_option            TEXT NOT NULL,
            concept_anchor            TEXT NOT NULL,
            -- JSON array stored as TEXT
            concepts_used             TEXT NOT NULL,
            -- Denormalized display text per language
            -- For non-table questions this must be non-null; for table
            -- questions it may be NULL and content comes from question_tables.
            en_display_text           TEXT,
            hi_display_text           TEXT,
            has_table                 INTEGER NOT NULL DEFAULT 0
        );

        CREATE INDEX IF NOT EXISTS idx_questions_subject
            ON questions(subject);
        CREATE INDEX IF NOT EXISTS idx_questions_subject_topic
            ON questions(subject, topic);

        ------------------------------------------------------------------
        -- Optional table layouts for questions with tables
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS question_tables (
            id              INTEGER PRIMARY KEY AUTOINCREMENT,
            question_uuid   TEXT NOT NULL,
            en_header_text  TEXT,
            en_footer_text  TEXT,
            en_columns      TEXT NOT NULL,          -- JSON array
            en_rows         TEXT NOT NULL,          -- JSON 2D array
            hi_header_text  TEXT,
            hi_footer_text  TEXT,
            hi_columns      TEXT NOT NULL,          -- JSON array
            hi_rows         TEXT NOT NULL,          -- JSON 2D array
            FOREIGN KEY (question_uuid) REFERENCES questions(uuid)
                ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX IF NOT EXISTS uq_question_tables_question
            ON question_tables(question_uuid);

        ------------------------------------------------------------------
        -- Explanations, per-language
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS explanations (
            id                      INTEGER PRIMARY KEY AUTOINCREMENT,
            question_uuid           TEXT NOT NULL,
            language                TEXT NOT NULL,   -- 'en' | 'hi'
            strong_distractor       TEXT NOT NULL,
            elimination_logic       TEXT NOT NULL,   -- JSON array TEXT
            upsc_trap_explanation   TEXT NOT NULL,
            final_explanation       TEXT NOT NULL,
            -- JSON array, nullable for non-statement questions
            statement_analysis      TEXT,
            FOREIGN KEY (question_uuid) REFERENCES questions(uuid)
                ON DELETE CASCADE
        );

        CREATE UNIQUE INDEX IF NOT EXISTS uq_explanations_question_lang
            ON explanations(question_uuid, language);

        ------------------------------------------------------------------
        -- Sessions and attempts (user state)
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS sessions (
            id                  TEXT PRIMARY KEY,
            -- store as seconds since epoch (INTEGER)
            created_at          INTEGER NOT NULL,
            completed_at        INTEGER,
            subject             TEXT NOT NULL,      -- plain English
            topic               TEXT,
            sub_topic           TEXT,
            mode                TEXT NOT NULL,      -- 'exam' | 'tutor' | 'review'
            status              TEXT NOT NULL,      -- 'in_progress' | 'completed' | ...
            question_count      INTEGER NOT NULL,
            score               INTEGER,
            is_timed            INTEGER NOT NULL,   -- 0/1
            time_limit_secs     INTEGER,
            exam_remaining_secs INTEGER,
            language            TEXT NOT NULL DEFAULT 'en'
        );

        CREATE TABLE IF NOT EXISTS attempts (
            id              TEXT PRIMARY KEY,
            session_id      TEXT NOT NULL,
            question_uuid   TEXT NOT NULL,
            position        INTEGER NOT NULL,
            selected_option TEXT,
            is_correct      INTEGER,
            status          TEXT NOT NULL DEFAULT 'unattempted',
            time_spent_secs INTEGER,
            flagged         INTEGER NOT NULL DEFAULT 0,
            -- seconds since epoch, nullable
            attempted_at    INTEGER,
            FOREIGN KEY (session_id)    REFERENCES sessions(id)
                ON DELETE CASCADE,
            FOREIGN KEY (question_uuid) REFERENCES questions(uuid)
                ON DELETE CASCADE
        );

        CREATE INDEX IF NOT EXISTS idx_attempts_session
            ON attempts(session_id);
        CREATE INDEX IF NOT EXISTS idx_attempts_question
            ON attempts(question_uuid);

        ------------------------------------------------------------------
        -- Bookmarks and revision queue (user state)
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS bookmarks (
            id              TEXT PRIMARY KEY,
            question_uuid   TEXT NOT NULL UNIQUE,
            created_at      INTEGER NOT NULL,
            user_note       TEXT,
            FOREIGN KEY (question_uuid) REFERENCES questions(uuid)
                ON DELETE CASCADE
        );

        CREATE TABLE IF NOT EXISTS revision_queue (
            id                                      TEXT PRIMARY KEY,
            question_uuid                           TEXT NOT NULL UNIQUE,
            date_added_to_queue                     INTEGER NOT NULL,
            number_of_times_answered_correctly_in_revision   INTEGER NOT NULL DEFAULT 0,
            number_of_times_answered_incorrectly_in_revision INTEGER NOT NULL DEFAULT 0,
            has_graduated_from_queue                INTEGER NOT NULL DEFAULT 0,
            date_graduated                          INTEGER,
            FOREIGN KEY (question_uuid) REFERENCES questions(uuid)
                ON DELETE CASCADE
        );

        ------------------------------------------------------------------
        -- Aggregated topic stats
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS user_topic_stats (
            id                  INTEGER PRIMARY KEY AUTOINCREMENT,
            subject             TEXT NOT NULL,
            topic               TEXT NOT NULL,
            total_attempted     INTEGER NOT NULL DEFAULT 0,
            total_correct       INTEGER NOT NULL DEFAULT 0,
            accuracy_percentage REAL    NOT NULL DEFAULT 0.0,
            last_attempted_at   INTEGER NOT NULL,
            UNIQUE(subject, topic)
        );

        ------------------------------------------------------------------
        -- Topic translations (soft lookup)
        ------------------------------------------------------------------
        CREATE TABLE IF NOT EXISTS topic_translations (
            id           INTEGER PRIMARY KEY AUTOINCREMENT,
            english_name TEXT NOT NULL,
            hindi_name   TEXT NOT NULL
        );

        CREATE UNIQUE INDEX IF NOT EXISTS uq_topic_translations_english
            ON topic_translations(english_name);
        """
    )

    conn.commit()


# ----------------------------------------------------------------------
# Optional helpers to insert static data
# ----------------------------------------------------------------------

def insert_questions(
    conn: sqlite3.Connection,
    rows: Iterable[Mapping[str, Any]],
) -> None:
    """
    Insert many questions.

    Each row should be a dict with keys:
      uuid, subject, topic, sub_topic,
      question_type, trap_type, correct_option,
      concept_anchor, concepts_used (JSON string),
      en_display_text, hi_display_text, has_table (0/1)
    """
    cur = conn.cursor()
    sql = """
        INSERT INTO questions (
          uuid,
          subject,
          topic,
          sub_topic,
          question_type,
          trap_type,
          correct_option,
          concept_anchor,
          concepts_used,
          en_display_text,
          hi_display_text,
          has_table
        ) VALUES (
          :uuid,
          :subject,
          :topic,
          :sub_topic,
          :question_type,
          :trap_type,
          :correct_option,
          :concept_anchor,
          :concepts_used,
          :en_display_text,
          :hi_display_text,
          :has_table
        );
        """
    rows_list = list(rows)
    try:
        cur.executemany(sql, rows_list)
        conn.commit()
    except sqlite3.IntegrityError as exc:
        # Retry one-by-one to identify the offending uuid(s).
        print("[ERROR] Batch insert into questions failed; locating bad row...")
        conn.rollback()
        for row in rows_list:
            try:
                cur.execute(sql, row)
            except sqlite3.IntegrityError as row_exc:
                print(
                    f"[ERROR] Failed to insert question uuid={row.get('uuid')}: "
                    f"{row_exc}"
                )
                # Re-raise the original exception after logging the uuid.
                raise exc
        # If we somehow get here, re-raise the original error.
        raise


def insert_question_tables(
    conn: sqlite3.Connection,
    rows: Iterable[Mapping[str, Any]],
) -> None:
    """
    Insert many question table layouts.

    Each row:
      question_uuid,
      en_header_text, en_footer_text, en_columns, en_rows,
      hi_header_text, hi_footer_text, hi_columns, hi_rows
    (all columns/rows are JSON strings).
    """
    cur = conn.cursor()
    cur.executemany(
        """
        INSERT INTO question_tables (
          question_uuid,
          en_header_text,
          en_footer_text,
          en_columns,
          en_rows,
          hi_header_text,
          hi_footer_text,
          hi_columns,
          hi_rows
        ) VALUES (
          :question_uuid,
          :en_header_text,
          :en_footer_text,
          :en_columns,
          :en_rows,
          :hi_header_text,
          :hi_footer_text,
          :hi_columns,
          :hi_rows
        );
        """,
        list(rows),
    )
    conn.commit()


def insert_explanations(
    conn: sqlite3.Connection,
    rows: Iterable[Mapping[str, Any]],
) -> None:
    """
    Insert many explanation rows.

    Each row: question_uuid, language, strong_distractor,
              elimination_logic (JSON), upsc_trap_explanation,
              final_explanation, statement_analysis (JSON or None).
    """
    cur = conn.cursor()
    cur.executemany(
        """
        INSERT INTO explanations (
          question_uuid,
          language,
          strong_distractor,
          elimination_logic,
          upsc_trap_explanation,
          final_explanation,
          statement_analysis
        ) VALUES (
          :question_uuid,
          :language,
          :strong_distractor,
          :elimination_logic,
          :upsc_trap_explanation,
          :final_explanation,
          :statement_analysis
        );
        """,
        list(rows),
    )
    conn.commit()


def insert_topic_translations(
    conn: sqlite3.Connection,
    rows: Iterable[Mapping[str, Any]],
) -> None:
    """
    Insert many topic translations.

    Each row: english_name, hindi_name.
    """
    cur = conn.cursor()
    cur.executemany(
        """
        INSERT INTO topic_translations (english_name, hindi_name)
        VALUES (:english_name, :hindi_name);
        """,
        list(rows),
    )
    conn.commit()


# ----------------------------------------------------------------------
# Main entry point / data hook
# ----------------------------------------------------------------------

def populate_static_data(conn: sqlite3.Connection) -> None:
    """
    Populate static question data from assets/final_cleaned_questions/.

    Directory layout (per subject):
      assets/final_cleaned_questions/
        ancient_history/
          1.json
          2.json
          ...
        polity/
          1.json
          ...

    Each *.json file contains a list of question objects with shape:
      {
        "uuid": "...",
        "meta": {
          "subject": "...",
          "topic": "...",
          "sub_topic": "...",
          "concepts_used": [...]
        },
        "shared": {
          "correct_option": "a"/"b"/"c"/"d",
          "question_type": "...",
          "trap_type": "...",
          "concept_anchor": "...",
          "has_table": false
        },
        "en": { "display_text": "...", ... },
        "hi": { "display_text": "...", ... }
      }
    """
    project_root = Path(__file__).resolve().parents[1]
    base_dir = project_root / "assets" / "final_cleaned_questions"

    if not base_dir.exists():
        print(f"[WARN] Directory not found: {base_dir}")
        return

    total_questions = 0
    total_explanations = 0
    total_question_tables = 0

    # Walk each subject directory and aggregate rows for batch insert.
    for subject_dir in sorted(p for p in base_dir.iterdir() if p.is_dir()):
        subject_rows: list[Mapping[str, Any]] = []
        explanation_rows: list[Mapping[str, Any]] = []
        table_rows: list[Mapping[str, Any]] = []
        per_subject_count = 0

        json_files = sorted(subject_dir.glob("*.json"))
        if not json_files:
            print(f"[INFO] Subject '{subject_dir.name}': no JSON files found")
            continue

        for json_file in json_files:
            try:
                with json_file.open("r", encoding="utf-8") as f:
                    data = json.load(f)
            except Exception as exc:  # pragma: no cover - defensive
                print(f"[WARN] Failed to read {json_file}: {exc}")
                continue

            if not isinstance(data, list):
                print(f"[WARN] Expected list in {json_file}, got {type(data).__name__}")
                continue

            for item in data:
                try:
                    meta = item["meta"]
                    shared = item["shared"]
                    en = item["en"]
                    hi = item["hi"]

                    subject = meta["subject"]
                    topic = meta["topic"]
                    sub_topic = meta["sub_topic"]

                    concepts_used = meta.get("concepts_used", [])
                    row = {
                        "uuid": item["uuid"],
                        "subject": subject,
                        "topic": topic,
                        "sub_topic": sub_topic,
                        "question_type": shared["question_type"],
                        "trap_type": shared.get("trap_type"),
                        "correct_option": shared["correct_option"],
                        "concept_anchor": shared["concept_anchor"],
                        "concepts_used": json.dumps(
                            concepts_used,
                            ensure_ascii=False,
                        ),
                        "en_display_text": en["display_text"],
                        "hi_display_text": hi["display_text"],
                        "has_table": 1 if shared.get("has_table") else 0,
                    }
                    subject_rows.append(row)

                    for language_key in ("en", "hi"):
                        payload = item[language_key]
                        explanation_rows.append(
                            {
                                "question_uuid": item["uuid"],
                                "language": language_key,
                                "strong_distractor": _as_non_null_text(
                                    payload.get("strong_distractor")
                                ),
                                "elimination_logic": json.dumps(
                                    payload.get("elimination_logic", []),
                                    ensure_ascii=False,
                                ),
                                "upsc_trap_explanation": _as_non_null_text(
                                    payload.get("upsc_trap_explanation")
                                ),
                                "final_explanation": _as_non_null_text(
                                    payload.get("final_explanation")
                                ),
                                "statement_analysis": (
                                    json.dumps(
                                        payload["statement_analysis"],
                                        ensure_ascii=False,
                                    )
                                    if payload.get("statement_analysis") is not None
                                    else None
                                ),
                            }
                        )

                    has_table = bool(shared.get("has_table"))
                    en_table = en.get("table_data")
                    hi_table = hi.get("table_data")
                    if has_table and en_table and hi_table:
                        table_rows.append(
                            {
                                "question_uuid": item["uuid"],
                                "en_header_text": en_table.get("header_text"),
                                "en_footer_text": en_table.get("footer_text"),
                                "en_columns": json.dumps(
                                    en_table.get("columns", []),
                                    ensure_ascii=False,
                                ),
                                "en_rows": json.dumps(
                                    en_table.get("rows", []),
                                    ensure_ascii=False,
                                ),
                                "hi_header_text": hi_table.get("header_text"),
                                "hi_footer_text": hi_table.get("footer_text"),
                                "hi_columns": json.dumps(
                                    hi_table.get("columns", []),
                                    ensure_ascii=False,
                                ),
                                "hi_rows": json.dumps(
                                    hi_table.get("rows", []),
                                    ensure_ascii=False,
                                ),
                            }
                        )
                    per_subject_count += 1
                except KeyError as exc:  # pragma: no cover - data validation
                    print(f"[WARN] Missing key {exc} in {json_file}")
                except Exception as exc:  # pragma: no cover - defensive
                    print(f"[WARN] Skipping malformed item in {json_file}: {exc}")

        if subject_rows:
            insert_questions(conn, subject_rows)
            insert_explanations(conn, explanation_rows)
            if table_rows:
                insert_question_tables(conn, table_rows)
            total_questions += len(subject_rows)
            total_explanations += len(explanation_rows)
            total_question_tables += len(table_rows)
            print(
                f"[INFO] Subject '{subject_dir.name}': "
                f"{per_subject_count} questions, "
                f"{len(explanation_rows)} explanations, "
                f"{len(table_rows)} question_tables inserted"
            )

    print(f"[INFO] Total questions inserted: {total_questions}")
    print(f"[INFO] Total explanations inserted: {total_explanations}")
    print(f"[INFO] Total question_tables inserted: {total_question_tables}")


def _parse_args(argv: list[str]) -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Build pre-populated UPSC Wars SQLite database."
    )
    parser.add_argument("out_path", help="Output SQLite file path")
    parser.add_argument(
        "--verify",
        action="store_true",
        help="Run post-build integrity checks",
    )
    return parser.parse_args(argv[1:])


def main(argv: list[str]) -> None:
    args = _parse_args(argv)
    out_path = Path(args.out_path).expanduser().resolve()
    out_path.parent.mkdir(parents=True, exist_ok=True)

    # Overwrite if exists
    if out_path.exists():
        out_path.unlink()

    conn = sqlite3.connect(str(out_path))
    try:
        create_schema(conn)
        populate_static_data(conn)
        if args.verify:
            verify_built_db(conn)
    finally:
        conn.close()

    print(f"Database created at {out_path}")


if __name__ == "__main__":
    main(sys.argv)

