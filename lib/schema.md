# App data stores — schema reference

This project uses **one on-device SQLite file** for questions and user progress, plus **Firebase Realtime Database** for chat and presence. Drift models live in `lib/core/database/user_db.dart`; the bundled file is produced by `tools/build_question_db.py` and copied at startup from `assets/db/upsc_wars_questions.db` to `upsc_wars_questions.db` under the app documents directory (`QuestionBankSetup` / `user_db_connection_io.dart`).

---

## SQLite — `upsc_wars_questions.db`

**`PRAGMA user_version`:** `5` (set in `build_question_db.py` and matched by `UserDatabase.schemaVersion`).

**Drift ↔ table names:** class `QuestionTranslations` → table **`explanations`**. class `SessionQuestions` → table **`attempts`**.

**Type mapping:** SQLite stores Drift `bool` as **INTEGER** `0`/`1` (with `CHECK` constraints from Drift). Drift `DateTime` is stored as **INTEGER** (Drift’s datetime encoding at runtime). The Python builder uses **Unix epoch seconds** for integer timestamps on the shipped asset (`sessions`, `bookmarks`, `revision_queue`, `user_topic_stats`, `user_feature_stats`, `user_trap_stats`); keep that consistent if you mix raw SQL and Drift on the same file.

**Foreign keys:** enabled in the builder script (`PRAGMA foreign_keys = ON`).

---

### `questions`

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `uuid` | TEXT | NOT NULL | — | PRIMARY KEY |
| `subject` | TEXT | NOT NULL | — | Display label (e.g. Polity) |
| `topic` | TEXT | NOT NULL | — | |
| `sub_topic` | TEXT | NOT NULL | — | |
| `question_type` | TEXT | NOT NULL | — | e.g. `direct`, `multi-statement-correct`, … |
| `trap_type` | TEXT | YES | — | Optional trap label |
| `correct_option` | TEXT | NOT NULL | — | `a`–`d` |
| `concept_anchor` | TEXT | NOT NULL | — | |
| `concepts_used` | TEXT | NOT NULL | — | JSON array as text |
| `en_display_text` | TEXT | YES | — | May be null when `has_table` supplies copy |
| `hi_display_text` | TEXT | YES | — | |
| `has_table` | INTEGER | NOT NULL | `0` | `0` / `1` |
| `negative_framing` | INTEGER | NOT NULL | `0` | `0` / `1` |
| `paper_order` | INTEGER | YES | — | 1-based order in a PYQ paper; null for non-PYQ |

**Indexes**

- `idx_questions_subject` ON (`subject`)
- `idx_questions_subject_topic` ON (`subject`, `topic`)

**FKs:** none (root entity).

---

### `explanations` (Drift: `QuestionTranslations`)

Physical tables created from the **asset builder** include a surrogate key. Drift’s Dart table does **not** declare `id`; it relies on `UNIQUE (question_uuid, language)`. The shipped DB still has `id` for SQLite convenience—Drift ignores the extra column.

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | INTEGER | NOT NULL | AUTOINCREMENT | PRIMARY KEY (builder / bundled DB) |
| `question_uuid` | TEXT | NOT NULL | — | FK → `questions.uuid` ON DELETE CASCADE |
| `language` | TEXT | NOT NULL | — | `en` \| `hi` |
| `strong_distractor` | TEXT | NOT NULL | — | |
| `elimination_logic` | TEXT | NOT NULL | — | JSON array as text |
| `upsc_trap_explanation` | TEXT | NOT NULL | — | |
| `final_explanation` | TEXT | NOT NULL | — | |
| `statement_analysis` | TEXT | YES | — | JSON array; statement-style items |

**Constraints / indexes**

- UNIQUE (`question_uuid`, `language`) — index name `uq_explanations_question_lang`

---

### `question_tables` (Drift: `QuestionTables`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | INTEGER | NOT NULL | AUTOINCREMENT | PRIMARY KEY |
| `question_uuid` | TEXT | NOT NULL | — | FK → `questions.uuid` ON DELETE CASCADE |
| `en_header_text` | TEXT | YES | — | |
| `en_footer_text` | TEXT | YES | — | |
| `en_columns` | TEXT | NOT NULL | — | JSON array of headers |
| `en_rows` | TEXT | NOT NULL | — | JSON 2D array |
| `hi_header_text` | TEXT | YES | — | |
| `hi_footer_text` | TEXT | YES | — | |
| `hi_columns` | TEXT | NOT NULL | — | JSON array |
| `hi_rows` | TEXT | NOT NULL | — | JSON 2D array |

**Constraints / indexes**

- UNIQUE (`question_uuid`) — `uq_question_tables_question`

---

### `topic_translations` (Drift: `TopicTranslations`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | INTEGER | NOT NULL | AUTOINCREMENT | PRIMARY KEY |
| `english_name` | TEXT | NOT NULL | — | |
| `hindi_name` | TEXT | NOT NULL | — | |

**Constraints / indexes**

- UNIQUE (`english_name`) — `uq_topic_translations_english`

**Note:** Soft lookup for Hindi labels; no FK to `questions`.

---

### `sessions` (Drift: `Sessions`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | TEXT | NOT NULL | — | PRIMARY KEY, UUID string |
| `created_at` | INTEGER | NOT NULL | — | Epoch seconds on asset; Drift `DateTime` |
| `completed_at` | INTEGER | YES | — | |
| `subject` | TEXT | NOT NULL | — | |
| `topic` | TEXT | YES | — | null = whole-subject / special packs |
| `sub_topic` | TEXT | YES | — | |
| `mode` | TEXT | NOT NULL | — | App persists `exam` \| `learning` |
| `status` | TEXT | NOT NULL | — | e.g. `in_progress`, `completed`, `abandoned` |
| `question_count` | INTEGER | NOT NULL | — | |
| `score` | INTEGER | YES | — | |
| `is_timed` | INTEGER | NOT NULL | — | `0` / `1` (no default in shipped SQL) |
| `time_limit_secs` | INTEGER | YES | — | |
| `exam_remaining_secs` | INTEGER | YES | — | |
| `language` | TEXT | NOT NULL | `'en'` | `en` \| `hi` |
| `analytics_feature_key` | TEXT | YES | — | Optional analytics bucket |

---

### `attempts` (Drift: `SessionQuestions`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | TEXT | NOT NULL | — | PRIMARY KEY, UUID |
| `session_id` | TEXT | NOT NULL | — | FK → `sessions.id` ON DELETE CASCADE |
| `question_uuid` | TEXT | NOT NULL | — | FK → `questions.uuid` ON DELETE CASCADE |
| `position` | INTEGER | NOT NULL | — | 1-based order in session |
| `selected_option` | TEXT | YES | — | `a`–`d` |
| `is_correct` | INTEGER | YES | — | `0` / `1`; null if not scored |
| `status` | TEXT | NOT NULL | `'unattempted'` | `unattempted` \| `correct` \| `wrong` \| `timed_out` |
| `time_spent_secs` | INTEGER | YES | — | |
| `flagged` | INTEGER | NOT NULL | `0` | `0` / `1` |
| `attempted_at` | INTEGER | YES | — | Epoch seconds (asset); Drift `DateTime` |
| `confidence` | TEXT | YES | — | `very_sure` \| `somewhat_sure` \| `guessing`; null if unset |

**Indexes**

- `idx_attempts_session` ON (`session_id`)
- `idx_attempts_question` ON (`question_uuid`)

---

### `bookmarks` (Drift: `Bookmarks`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | TEXT | NOT NULL | — | PRIMARY KEY, UUID |
| `question_uuid` | TEXT | NOT NULL | — | UNIQUE, FK → `questions.uuid` ON DELETE CASCADE |
| `created_at` | INTEGER | NOT NULL | — | Epoch seconds / Drift `DateTime` |
| `user_note` | TEXT | YES | — | |

---

### `revision_queue` (Drift: `RevisionQueue`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | TEXT | NOT NULL | — | PRIMARY KEY, UUID |
| `question_uuid` | TEXT | NOT NULL | — | UNIQUE, FK → `questions.uuid` ON DELETE CASCADE |
| `date_added_to_queue` | INTEGER | NOT NULL | — | Epoch seconds / Drift `DateTime` |
| `number_of_times_answered_correctly_in_revision` | INTEGER | NOT NULL | `0` | |
| `number_of_times_answered_incorrectly_in_revision` | INTEGER | NOT NULL | `0` | |
| `has_graduated_from_queue` | INTEGER | NOT NULL | `0` | `0` / `1` |
| `date_graduated` | INTEGER | YES | — | Epoch seconds / Drift `DateTime` |

---

### `user_topic_stats` (Drift: `UserTopicStats`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `id` | INTEGER | NOT NULL | AUTOINCREMENT | PRIMARY KEY |
| `subject` | TEXT | NOT NULL | — | |
| `topic` | TEXT | NOT NULL | — | |
| `total_attempted` | INTEGER | NOT NULL | `0` | |
| `total_correct` | INTEGER | NOT NULL | `0` | |
| `accuracy_percentage` | REAL | NOT NULL | `0.0` | Percent 0–100 |
| `last_attempted_at` | INTEGER | NOT NULL | — | Epoch seconds / Drift `DateTime` |
| `wrong_attempts` | INTEGER | NOT NULL | `0` | |
| `total_time_spent_secs` | INTEGER | NOT NULL | `0` | |

**Constraints**

- UNIQUE (`subject`, `topic`)

---

### `user_feature_stats` (Drift: `UserFeatureStats`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `feature_name` | TEXT | NOT NULL | — | PRIMARY KEY |
| `total_views` | INTEGER | NOT NULL | `0` | |
| `total_starts` | INTEGER | NOT NULL | `0` | |
| `total_completions` | INTEGER | NOT NULL | `0` | |
| `last_used_at` | INTEGER | NOT NULL | — | Epoch seconds / Drift `DateTime` |

---

### `user_trap_stats` (Drift: `UserTrapStats`)

| Column | SQLite type | Null | Default | Notes |
|--------|-------------|------|---------|--------|
| `trap_type` | TEXT | NOT NULL | — | PRIMARY KEY |
| `total_failures` | INTEGER | NOT NULL | `0` | |
| `last_failed_at` | INTEGER | NOT NULL | — | Epoch seconds / Drift `DateTime` |

---

### SQLite indexes vs Drift `onCreate`

Drift’s `UserDatabase.migration.onCreate` creates **`idx_questions_subject`** only. The **bundled** DB from `build_question_db.py` also creates **`idx_questions_subject_topic`**. Treat the builder script as the source of truth for the shipped file.

---

## Firebase Realtime Database (JSON)

Rules are in `database.rules.json` (authenticated read/write on the trees below). Shapes follow `RealtimeChatService`.

### `chatMessages/{chatId}/{messageId}`

| Field | Type | Notes |
|-------|------|--------|
| `senderEmail` | string | Lowercased email |
| `text` | string | |
| `createdAt` | number | `ServerValue.timestamp` |

### `chatThreads/{chatId}`

| Field | Type | Notes |
|-------|------|--------|
| `participantEmails` | array of string | Sorted pair of emails |
| `participants/{userKey}` | boolean | `userKey` from `ChatIds.emailKey` |
| `lastMessageText` | string | |
| `lastMessageBy` | string | Email |
| `lastMessageAt` | number | Server timestamp |
| `updatedAt` | number | Server timestamp |
| `unread/{userKey}` | number | Count; optional per `ChatRuntimeConfig` |

### `chatTyping/{chatId}/{userKey}`

| Value | Type | Notes |
|-------|------|--------|
| (leaf) | boolean | `true` while typing; removed on disconnect |

### `presence/{userKey}`

| Field | Type | Notes |
|-------|------|--------|
| `isOnline` | boolean | |
| `lastSeenAt` | number | Server timestamp |

---

## Other cloud data

Community and related features also use **Firestore** (e.g. bucket/presence documents). That is separate from this file; see `lib/features/community/` and repository code for field-level detail.
