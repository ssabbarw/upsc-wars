# Database schema (SQLite)

This document matches the unified app database: Drift definitions in `lib/core/database/user_db.dart` and the shipped file produced by `tools/build_question_db.py`.

**Drift ↔ SQLite names:** Drift class `QuestionTranslations` maps to table **`explanations`**. Drift class `SessionQuestions` maps to table **`attempts`**.

**Storage note:** Drift maps `bool` to SQLite **INTEGER** (0/1). Drift maps `DateTime` to SQLite **INTEGER** using its built-in datetime encoding (not necessarily plain Unix seconds). The offline builder (`build_question_db.py`) uses **INTEGER** Unix **seconds** for `sessions`, `bookmarks`, `revision_queue`, and `user_topic_stats` timestamps on the prebuilt asset; at runtime the app may insert rows through Drift with the same logical columns—keep formats consistent if mixing raw SQL and Drift writes.

**Metadata:** `PRAGMA user_version = 1` is set when building the asset DB.

---

## `questions`

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `uuid` | TEXT | PRIMARY KEY |
| `subject` | TEXT | NOT NULL — display string (e.g. `Ancient History`, `Polity`) |
| `topic` | TEXT | NOT NULL |
| `sub_topic` | TEXT | NOT NULL |
| `question_type` | TEXT | NOT NULL — e.g. `direct`, `multi-statement-correct`, `multi-statement-incorrect` |
| `trap_type` | TEXT | NULLABLE |
| `correct_option` | TEXT | NOT NULL — `a` \| `b` \| `c` \| `d` |
| `concept_anchor` | TEXT | NOT NULL |
| `concepts_used` | TEXT | NOT NULL — JSON array |
| `en_display_text` | TEXT | NULLABLE — may be null for table-first questions |
| `hi_display_text` | TEXT | NULLABLE |
| `has_table` | INTEGER | NOT NULL DEFAULT 0 — 0 \| 1 |

**Indexes**

- `idx_questions_subject` ON (`subject`)
- `idx_questions_subject_topic` ON (`subject`, `topic`)

---

## `explanations` (Drift: `QuestionTranslations`)

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `question_uuid` | TEXT | NOT NULL, FK → `questions.uuid` ON DELETE CASCADE |
| `language` | TEXT | NOT NULL — `en` \| `hi` |
| `strong_distractor` | TEXT | NOT NULL |
| `elimination_logic` | TEXT | NOT NULL — JSON array |
| `upsc_trap_explanation` | TEXT | NOT NULL |
| `final_explanation` | TEXT | NOT NULL |
| `statement_analysis` | TEXT | NULLABLE — JSON array; statement-type questions |

**Constraints:** UNIQUE (`question_uuid`, `language`)

---

## `question_tables` (Drift: `QuestionTables`)

One row per question that has a table: bilingual payloads in the same row.

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `question_uuid` | TEXT | NOT NULL, FK → `questions.uuid` ON DELETE CASCADE |
| `en_header_text` | TEXT | NULLABLE |
| `en_footer_text` | TEXT | NULLABLE |
| `en_columns` | TEXT | NOT NULL — JSON array of header strings |
| `en_rows` | TEXT | NOT NULL — JSON 2D array of cell values |
| `hi_header_text` | TEXT | NULLABLE |
| `hi_footer_text` | TEXT | NULLABLE |
| `hi_columns` | TEXT | NOT NULL — JSON array |
| `hi_rows` | TEXT | NOT NULL — JSON 2D array |

**Constraints:** UNIQUE (`question_uuid`)

---

## `topic_translations`

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `english_name` | TEXT | NOT NULL |
| `hindi_name` | TEXT | NOT NULL |

**Constraints:** UNIQUE (`english_name`)

**Note:** Soft lookup — `questions.topic` / `questions.sub_topic` can be matched to `english_name`. No FK. The offline question DB builder may leave this table empty until Hindi topic names are available.

---

## `sessions`

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | TEXT | PRIMARY KEY — UUID string |
| `created_at` | INTEGER | NOT NULL — Unix time (builder); Drift `DateTime` |
| `completed_at` | INTEGER | NULLABLE |
| `subject` | TEXT | NOT NULL |
| `topic` | TEXT | NULLABLE — null = whole-subject session |
| `sub_topic` | TEXT | NULLABLE |
| `mode` | TEXT | NOT NULL — app uses `exam` \| `learning` (history/filters may reference these) |
| `status` | TEXT | NOT NULL — e.g. `in_progress`, `completed`, `abandoned` |
| `question_count` | INTEGER | NOT NULL |
| `score` | INTEGER | NULLABLE |
| `is_timed` | INTEGER | NOT NULL DEFAULT 0 — 0 \| 1 |
| `time_limit_secs` | INTEGER | NULLABLE |
| `exam_remaining_secs` | INTEGER | NULLABLE |
| `language` | TEXT | NOT NULL DEFAULT `en` — `en` \| `hi` |

**Indexes:** None required by builder; add in SQL if you introduce `idx_sessions_status` etc.

---

## `attempts` (Drift: `SessionQuestions`)

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | TEXT | PRIMARY KEY — UUID string |
| `session_id` | TEXT | NOT NULL, FK → `sessions.id` ON DELETE CASCADE |
| `question_uuid` | TEXT | NOT NULL, FK → `questions.uuid` ON DELETE CASCADE |
| `position` | INTEGER | NOT NULL — 1-based order in session |
| `selected_option` | TEXT | NULLABLE — `a` \| `b` \| `c` \| `d` |
| `is_correct` | INTEGER | NULLABLE — 0 \| 1; null if unattempted |
| `status` | TEXT | NOT NULL DEFAULT `unattempted` — app uses `unattempted` \| `correct` \| `wrong` \| `timed_out` |
| `time_spent_secs` | INTEGER | NULLABLE |
| `flagged` | INTEGER | NOT NULL DEFAULT 0 — 0 \| 1 |
| `attempted_at` | INTEGER | NULLABLE — Unix time |

**Indexes**

- `idx_attempts_session` ON (`session_id`)
- `idx_attempts_question` ON (`question_uuid`)

---

## `bookmarks`

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | TEXT | PRIMARY KEY — UUID string |
| `question_uuid` | TEXT | NOT NULL UNIQUE, FK → `questions.uuid` ON DELETE CASCADE |
| `created_at` | INTEGER | NOT NULL — Unix time (builder); Drift `DateTime` |
| `user_note` | TEXT | NULLABLE |

---

## `revision_queue`

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | TEXT | PRIMARY KEY — UUID string |
| `question_uuid` | TEXT | NOT NULL UNIQUE, FK → `questions.uuid` ON DELETE CASCADE |
| `date_added_to_queue` | INTEGER | NOT NULL — Unix time (builder); Drift `DateTime` |
| `number_of_times_answered_correctly_in_revision` | INTEGER | NOT NULL DEFAULT 0 |
| `number_of_times_answered_incorrectly_in_revision` | INTEGER | NOT NULL DEFAULT 0 |
| `has_graduated_from_queue` | INTEGER | NOT NULL DEFAULT 0 — 0 \| 1 |
| `date_graduated` | INTEGER | NULLABLE — Unix time |

---

## `user_topic_stats`

| Column | Type | Constraints / notes |
|--------|------|---------------------|
| `id` | INTEGER | PRIMARY KEY AUTOINCREMENT |
| `subject` | TEXT | NOT NULL |
| `topic` | TEXT | NOT NULL |
| `total_attempted` | INTEGER | NOT NULL DEFAULT 0 |
| `total_correct` | INTEGER | NOT NULL DEFAULT 0 |
| `accuracy_percentage` | REAL | NOT NULL DEFAULT 0.0 |
| `last_attempted_at` | INTEGER | NOT NULL — Unix time (builder); Drift `DateTime` |

**Constraints:** UNIQUE (`subject`, `topic`)

**Note:** No FK to `questions` or `attempts`. Rows are updated by app logic after session completion.
