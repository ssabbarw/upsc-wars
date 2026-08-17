"""
services/transformer.py

Maps raw LLM output → canonical Firestore / app question schema.

Each question is structured as:
    {
        "uuid": "...",
        "meta": {
            "gs_subject", "topic", "sub_topic", "concepts_used",
            "source_kind", "source_date", "source_year", "pool_order",
            "news_trigger", "news_summary", "source_name", "source_url",
            "news_importance", "difficulty", "fallback",
        },
        "shared": { question fields },
        "en":     { display fields },
        "hi":     { display fields — added later by translate call }
    }
"""

import logging
import uuid
from datetime import date, datetime, timedelta, timezone

from services.formatter import merge_hi_table_from_en, normalize_table_data
from config.settings import CA_TAGS

log = logging.getLogger(__name__)

VALID_QUESTION_TYPES = {"direct", "statement-based", "match-the-column"}

VALID_TRAP_TYPES = {
    "conflation", "entity-swap", "geographic-swap",
    "partial-truth", "plausible-fabrication",
    "reversed-causation", "scope-extension", "temporal-swap",
}

CA_TAG_SET = set(CA_TAGS)

GS_SUBJECT_SLUG_MAP = {
    "Ancient History": "Ancient History",
    "Medieval History": "Medieval History",
    "Modern History": "Modern History",
    "Indian Polity & Governance": "Polity",
    "Indian Polity": "Polity",
    "Polity": "Polity",
    "Indian Economy": "Economy",
    "Economy": "Economy",
    "Environment & Ecology": "Environment",
    "Environment": "Environment",
    "Science & Technology": "Science & Technology",
    "Geography": "Geography",
    "International Relations": "International Relations",
    "Art & Culture": "Art and Culture",
    "Art and Culture": "Art and Culture",
    "Social Issues": "Social Issues",
    "Internal Security": "Internal Security",
    "Current affairs": "Current affairs",
    "Current Affairs": "Current affairs",
}


def sanitize_ca_tags(raw) -> list[str]:
    if not isinstance(raw, list):
        if isinstance(raw, str) and raw.strip():
            raw = [raw]
        else:
            raw = []
    out = []
    seen = set()
    for item in raw:
        tag = str(item or "").strip()
        if not tag or tag in seen or tag not in CA_TAG_SET:
            continue
        seen.add(tag)
        out.append(tag)
        if len(out) >= 3:
            break
    return out


def _normalize_statement_analysis(raw):
    if not isinstance(raw, list):
        return None
    out = []
    for item in raw:
        if not isinstance(item, dict):
            continue
        verdict = item.get("is_correct", item.get("correct", item.get("verdict")))
        if isinstance(verdict, bool):
            is_correct = verdict
        elif verdict is None:
            is_correct = False
        else:
            is_correct = str(verdict).strip().lower() in ("correct", "true", "yes")
        out.append({
            "statement": item.get("statement") or item.get("label") or "",
            "is_correct": is_correct,
            "reason": item.get("reason") or "",
        })
    return out or None


def normalize_gs_subject(raw: str) -> str:
    trimmed = (raw or "").strip()
    if not trimmed:
        return "General Studies"
    return GS_SUBJECT_SLUG_MAP.get(trimmed, trimmed)


def normalize_question_type(raw: str) -> str:
    t = (raw or "").strip()
    if t in ("statement-based", "multi-statement"):
        return "multi-statement-correct"
    return t or "direct"


def current_affairs_uuid(source_date: str, pool_order: int) -> str:
    return str(uuid.uuid5(uuid.NAMESPACE_URL, f"upsc-wars|ca|{source_date}|{pool_order}"))


# ── Validation ─────────────────────────────────────────────────────────────────

def _validate_question(q: dict):
    """Raise ValueError if question is missing critical fields."""
    qid = q.get("id", "?")

    if q.get("question_type") not in VALID_QUESTION_TYPES:
        raise ValueError(
            f"Q{qid}: invalid question_type '{q.get('question_type')}'. "
            f"Must be one of {VALID_QUESTION_TYPES}"
        )

    if q.get("trap_type") not in VALID_TRAP_TYPES:
        log.warning(f"Q{qid}: unknown trap_type '{q.get('trap_type')}' — keeping as-is")

    if not q.get("correct_option"):
        raise ValueError(f"Q{qid}: missing correct_option")

    if not q.get("final_explanation"):
        raise ValueError(f"Q{qid}: missing final_explanation")

    if q.get("question_type") == "statement-based":
        if not q.get("statement_analysis"):
            raise ValueError(f"Q{qid}: statement-based question missing statement_analysis")
        if not q.get("display_text"):
            raise ValueError(f"Q{qid}: statement-based question missing display_text")

    if q.get("question_type") == "match-the-column":
        if not q.get("table_data"):
            raise ValueError(f"Q{qid}: match-the-column question missing table_data")
        if q.get("display_text") is not None:
            log.warning(f"Q{qid}: match-the-column should have display_text=null — forcing null")

    if q.get("question_type") == "direct":
        if not q.get("display_text"):
            raise ValueError(f"Q{qid}: direct question missing display_text")


# ── Core transformer ───────────────────────────────────────────────────────────

def transform_question(
    q: dict,
    current_affairs_date: str,
    current_affairs_month: str,
    pool_order: int,
) -> dict:
    """
    Transform a single flat LLM question dict into the canonical schema.

    hi section is NOT added here — it is added after Hindi translation.
    """
    _validate_question(q)
    qid = q.get("id", "?")

    correct_option = str(q.get("correct_option", "")).strip().lower().lstrip("(").rstrip(")")
    gs_subject = normalize_gs_subject(q.get("subject", ""))
    topic = (q.get("topic") or "").strip() or gs_subject
    ca_tags = sanitize_ca_tags(q.get("ca_tags") or q.get("tags"))
    sub_topic = ca_tags[0] if ca_tags else "Current Affairs"
    question_type = normalize_question_type(q.get("question_type", "direct"))

    meta = {
        "gs_subject": gs_subject,
        "topic": topic,
        "sub_topic": sub_topic,
        "ca_tags": ca_tags,
        "concepts_used": ca_tags,
        "source_kind": "current_affairs",
        "source_date": current_affairs_date,
        "source_year": None,
        "pool_order": pool_order,
        "difficulty": q.get("difficulty", "medium"),
        "fallback": q.get("fallback", False),
        "news_trigger": q.get("news_trigger", ""),
        "news_summary": q.get("news_summary", ""),
        "source_name": q.get("source_name", ""),
        "source_url": q.get("source_url", ""),
        "news_importance": q.get("news_importance", 1),
        "current_affairs_date": current_affairs_date,
        "current_affairs_month": current_affairs_month,
    }

    is_table_question = q.get("question_type") == "match-the-column"
    raw_table_data = q.get("table_data") if (
        q.get("has_table") or is_table_question or q.get("table_data")
    ) else None

    shared = {
        "question_type": question_type,
        "trap_type": q.get("trap_type", ""),
        "concept_anchor": q.get("concept_anchor", ""),
        "has_table": bool(raw_table_data) or is_table_question,
        "correct_option": correct_option,
    }

    en = {
        "display_text": q.get("display_text") if q.get("question_type") != "match-the-column" else None,
        "table_data": normalize_table_data(raw_table_data),
        "statement_analysis": _normalize_statement_analysis(q.get("statement_analysis"))
            if q.get("question_type") == "statement-based" else None,
        "strong_distractor": q.get("strong_distractor", ""),
        "elimination_logic": q.get("elimination_logic", []),
        "upsc_trap_explanation": q.get("upsc_trap_explanation", ""),
        "final_explanation": q.get("final_explanation", ""),
    }

    log.info(f"  Q{qid} transformed → {shared['question_type']} / {shared['trap_type']}")

    return {
        "draft_id": f"d{pool_order}",
        "chosen": False,
        "uuid": current_affairs_uuid(current_affairs_date, pool_order),
        "meta": meta,
        "shared": shared,
        "en": en,
        "hi": {},
    }


def transform_all_questions(
    raw_questions: list[dict],
    current_affairs_date: str,
    current_affairs_month: str,
) -> list[dict]:
    """
    Transform all LLM questions. Skips invalid questions with a warning
    instead of crashing the whole pipeline.
    """
    transformed = []
    for i, q in enumerate(raw_questions):
        try:
            transformed.append(
                transform_question(
                    q,
                    current_affairs_date,
                    current_affairs_month,
                    pool_order=i + 1,
                )
            )
        except ValueError as e:
            log.warning(f"Skipping question due to validation error: {e}")
    return transformed


# ── Hindi merge ────────────────────────────────────────────────────────────────

def add_hindi_to_questions(
    transformed_questions: list[dict],
    hindi_questions: list[dict],
) -> list[dict]:
    """
    Merge Hindi translation into transformed questions.

    Matches by position (index). If Hindi list is shorter or translation
    failed, hi section is set to empty dict for that question.
    """
    for i, q in enumerate(transformed_questions):
        if i < len(hindi_questions):
            hi_q = hindi_questions[i]
            en_table = (q.get("en") or {}).get("table_data")
            hi_table = merge_hi_table_from_en(en_table, hi_q.get("table_data"))
            q["hi"] = {
                "display_text":          hi_q.get("display_text"),
                "table_data":            hi_table,
                "statement_analysis":    hi_q.get("statement_analysis"),
                "strong_distractor":     hi_q.get("strong_distractor", ""),
                "elimination_logic":     hi_q.get("elimination_logic", []),
                "upsc_trap_explanation": hi_q.get("upsc_trap_explanation", ""),
                "final_explanation":     hi_q.get("final_explanation", ""),
            }
        else:
            log.warning(f"Q{i+1}: no Hindi translation available — hi section empty")
            q["hi"] = {}
    return transformed_questions


# ── Document builder ───────────────────────────────────────────────────────────

def build_firestore_document(
    transformed_questions: list[dict],
    raw_data:              dict,
    reachable_urls:        list[dict],
    failed_urls:           list[dict],
    target_date:           date,
    prompt_version:        str,
    sonnet_model:          str,
    haiku_model:           str,
) -> dict:
    """
    Build the final Firestore document from transformed questions + metadata.

    Structure:
        {
            "metadata": { pipeline run info },
            "questions": [ { uuid, meta, shared, en, hi }, ... ]
        }
    """
    date_str  = target_date.strftime("%Y-%m-%d")
    month_str = target_date.strftime("%Y-%m")

    return {
        "metadata": {
            "date":                  date_str,
            "current_affairs_month": month_str,
            "question_count":        len(transformed_questions),
            "news_items_found":      raw_data.get("news_items_found", []),
            "topics_covered":        raw_data.get("topics_covered", []),
            "subjects_covered":      list({
                q["meta"]["gs_subject"] for q in transformed_questions
            }),
            "prompt_version":        prompt_version,
            "model_en":              sonnet_model,
            "model_hi":              haiku_model,
            "generated_at":          raw_data.get("generated_at", ""),
            "reachable_urls":        [u["name"] for u in reachable_urls],
            "failed_urls":           [u["name"] for u in failed_urls],
            "hindi_available":       any(q.get("hi") for q in transformed_questions),
            "schema_version":        2,
        },
        "questions": transformed_questions,
    }


def build_draft_document(
    transformed_questions: list[dict],
    raw_data:              dict,
    reachable_urls:        list[dict],
    failed_urls:           list[dict],
    target_date:           date,
    prompt_version:        str,
    sonnet_model:          str,
    is_weekend_pack:       bool,
) -> dict:
    """English-only admin draft. Hindi is added on publish."""
    date_str = target_date.strftime("%Y-%m-%d")
    opens = datetime(
        target_date.year, target_date.month, target_date.day, 6, 0
    ) + timedelta(days=1)
    return {
        "status": "ready",
        "content_date": date_str,
        "is_weekend_pack": is_weekend_pack,
        "opens_at": opens.isoformat(),
        "chosen_uuids": [],
        "question_count": len(transformed_questions),
        "hindi_available": False,
        "published_at": None,
        "generated_at": datetime.now(timezone.utc).isoformat(),
        "metadata": {
            "date": date_str,
            "current_affairs_month": target_date.strftime("%Y-%m"),
            "question_count": len(transformed_questions),
            "news_items_found": raw_data.get("news_items_found", []),
            "topics_covered": raw_data.get("topics_covered", []),
            "subjects_covered": list({
                q["meta"]["gs_subject"] for q in transformed_questions
            }),
            "prompt_version": prompt_version,
            "model_en": sonnet_model,
            "reachable_urls": [u["name"] for u in reachable_urls],
            "failed_urls": [u["name"] for u in failed_urls],
            "schema_version": 3,
        },
        "questions": transformed_questions,
    }
