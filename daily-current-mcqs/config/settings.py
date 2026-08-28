"""
config/settings.py
All configuration loaded from environment variables.
Import this everywhere instead of calling os.getenv() directly.
"""

import os
from dotenv import load_dotenv

load_dotenv()
load_dotenv(".env.local", override=True)

# ── Anthropic ──────────────────────────────────────────────────────────────────
ANTHROPIC_API_KEY   = (
    os.getenv("ANTHROPIC_API_KEY_CA")
    or os.getenv("ANTHROPIC_API_KEY")
)
SONNET_MODEL        = "claude-sonnet-4-6"
HAIKU_MODEL         = "claude-haiku-4-5-20251001"

# Model used for MCQ generation — override via MCQ_MODEL env var
# Use claude-haiku-4-5-20251001 for cheap POC testing
# Use claude-sonnet-4-6 for production
MCQ_MODEL           = os.getenv("MCQ_MODEL", HAIKU_MODEL)
MCQ_MAX_TOKENS      = int(os.getenv("MCQ_MAX_TOKENS", 32000))
TRANSLATE_MAX_TOKENS = int(os.getenv("TRANSLATE_MAX_TOKENS", 16000))

# ── Firebase ───────────────────────────────────────────────────────────────────
# Do not use FIREBASE_* env names — Cloud Functions reserves that prefix.
FIREBASE_CREDS_PATH = (
    os.getenv("CA_FIREBASE_CREDENTIALS_PATH")
    or os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
    or "./firebase_credentials.json"
)
FIREBASE_PROJECT_ID = (
    os.getenv("CA_FIREBASE_PROJECT_ID")
    or os.getenv("GOOGLE_CLOUD_PROJECT")
    or os.getenv("GCLOUD_PROJECT")
)

# ── Email ──────────────────────────────────────────────────────────────────────
GMAIL_SENDER        = os.getenv("GMAIL_SENDER")
GMAIL_APP_PASSWORD  = os.getenv("GMAIL_APP_PASSWORD")
GMAIL_RECIPIENT     = os.getenv("GMAIL_RECIPIENT")

# ── Pipeline ───────────────────────────────────────────────────────────────────
QUESTIONS_TARGET        = int(os.getenv("QUESTIONS_TARGET", 10))
WEEKEND_QUESTIONS_TARGET = int(os.getenv("WEEKEND_QUESTIONS_TARGET", 10))
MIN_QUESTIONS_TO_WRITE  = int(os.getenv("MIN_QUESTIONS_TO_WRITE", 5))
PROMPT_VERSION          = os.getenv("PROMPT_VERSION", "1.4")
MAX_RETRIES             = int(os.getenv("MAX_RETRIES", 1))  # 1 = no auto-retry
QUESTIONS_MIN           = 1
QUESTIONS_MAX           = 50
TOPICS_PER_GENERATE_CALL = int(os.getenv("TOPICS_PER_GENERATE_CALL", 3))
PUBLISH_MIN             = 5
PUBLISH_MAX             = 10
ADMIN_NOTIFY_EMAIL      = os.getenv(
    "ADMIN_NOTIFY_EMAIL", "sachinsabbarwal@gmail.com"
).strip().lower()

GS_SUBJECTS = [
    "Ancient History",
    "Medieval History",
    "Modern History",
    "Indian Polity & Governance",
    "Indian Economy",
    "Environment & Ecology",
    "Science & Technology",
    "Geography",
    "International Relations",
    "Art & Culture",
    "Social Issues",
    "Internal Security",
]

CA_TAGS = [
    "Government schemes",
    "Laws, bills & judgments",
    "Institutions & bodies",
    "Reports & indices",
    "Indian map",
    "World map",
    "Species & protected areas",
    "Climate & conventions",
    "International groupings",
    "Budget, tax & fiscal",
    "Banking & RBI",
    "Agriculture & food",
    "Energy & infrastructure",
    "Science, space & nuclear",
    "Defence & security",
    "Health & social welfare",
    "Culture, GI & heritage",
]


def split_question_types(total: int) -> tuple[int, int, int, int]:
    """Split total into (statement-based, direct, factual direct, match-the-column)."""
    weights = (4, 3, 2, 1)
    raw = [total * w / sum(weights) for w in weights]
    counts = [int(x) for x in raw]
    for i in sorted(range(4), key=lambda i: raw[i] - counts[i], reverse=True):
        if sum(counts) >= total:
            break
        counts[i] += 1
    while sum(counts) > total:
        for i in sorted(range(4), key=lambda i: counts[i], reverse=True):
            if counts[i] > 0:
                counts[i] -= 1
                if sum(counts) == total:
                    break
    return tuple(counts)


def _difficulty_distribution(total: int) -> str:
    if total <= 0:
        return "- 1 medium"
    easy = 1 if total >= 2 else 0
    hard = 1 if total >= 3 else 0
    medium = max(0, total - easy - hard)
    if total == 1:
        medium = 1
    lines = []
    if easy:
        lines.append(f"- {easy} easy")
    if medium:
        lines.append(f"- {medium} medium")
    if hard:
        lines.append(f"- {hard} hard")
    return "\n".join(lines)


def question_prompt_params(questions_target: int) -> dict:
    """Template values for mcq_system.txt based on target question count."""
    if not QUESTIONS_MIN <= questions_target <= QUESTIONS_MAX:
        raise ValueError(
            f"questions_target must be between {QUESTIONS_MIN} and {QUESTIONS_MAX}, "
            f"got {questions_target}"
        )

    stmt, direct, factual, match = split_question_types(questions_target)
    lines = []
    if stmt:
        label = "question" if stmt == 1 else "questions"
        lines.append(f"- {stmt} statement-based {label}")
    if direct:
        label = "question" if direct == 1 else "questions"
        lines.append(f"- {direct} direct {label}")
    if factual:
        label = "question" if factual == 1 else "questions"
        lines.append(f"- {factual} factual direct {label} (conceptually significant facts)")
    if match:
        label = "question" if match == 1 else "questions"
        lines.append(f"- {match} match-the-column {label}")

    return {
        "questions_target": questions_target,
        "news_items_pool": questions_target + 2,
        "max_per_subject": max(1, round(questions_target * 2 / 10)),
        "format_distribution": "\n".join(lines),
        "difficulty_distribution": _difficulty_distribution(questions_target),
        "min_difficulty_each": max(1, round(questions_target * 2 / 10)),
        "ca_tags_list": "\n".join(f"- {t}" for t in CA_TAGS),
        "gs_subjects_list": "\n".join(f"- {s}" for s in GS_SUBJECTS),
    }

# ── File paths ─────────────────────────────────────────────────────────────────
URL_PATTERNS_FILE   = "./config/url_patterns.json"
TAXONOMY_FILE       = "./taxonomy.json"
PROMPTS_DIR         = "./prompts"

# ── Firestore collections ──────────────────────────────────────────────────────
DAILY_COLLECTION    = "daily_mcqs"
DRAFT_COLLECTION    = "daily_ca_drafts"