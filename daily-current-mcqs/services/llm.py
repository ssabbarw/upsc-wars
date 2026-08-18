"""
services/llm.py
All Anthropic API calls with retry and backoff.
One function per call — easy to test individually.
"""

import os
import json
import time
import logging
from typing import Optional

import anthropic

import config.settings as settings
from config.settings import (
    HAIKU_MODEL,
    MCQ_MAX_TOKENS,
    TRANSLATE_MAX_TOKENS,
    PROMPTS_DIR,
    MAX_RETRIES,
    QUESTIONS_TARGET,
    TOPICS_PER_GENERATE_CALL,
    PROMPT_VERSION,
    question_prompt_params,
    split_question_types,
)

log = logging.getLogger(__name__)
_client = None
_client_key = None
_override_at = 0.0
_OVERRIDE_TTL_SEC = 15.0


def apply_firestore_llm_overrides(*, force: bool = False) -> None:
    """Prefer admin-saved CA key/model from Firestore over env."""
    global _override_at
    now = time.time()
    if not force and _override_at and now - _override_at < _OVERRIDE_TTL_SEC:
        return
    try:
        from services.firestore import get_db

        snap = get_db().collection("admin_secrets").document("llm").get()
        _override_at = now
        if not snap.exists:
            return
        data = snap.to_dict() or {}
        key = str(data.get("ca_api_key") or "").strip()
        model = str(data.get("ca_model") or "").strip()
        if key:
            settings.ANTHROPIC_API_KEY = key
        if model:
            settings.MCQ_MODEL = model
    except Exception as e:
        log.warning("LLM Firestore override skipped: %s", e)


def get_client():
    """Anthropic client using the current CA key (env or Firestore)."""
    global _client, _client_key
    apply_firestore_llm_overrides()
    key = settings.ANTHROPIC_API_KEY
    if not key:
        raise RuntimeError(
            "CA Anthropic API key is not set. Add ANTHROPIC_API_KEY_CA "
            "or save it in Settings → LLM & API keys."
        )
    if _client is None or _client_key != key:
        _client = anthropic.Anthropic(api_key=key)
        _client_key = key
    return _client


# ── Prompt loader ──────────────────────────────────────────────────────────────

def load_prompt(filename: str) -> str:
    """Load a prompt from the prompts directory"""
    path = os.path.join(PROMPTS_DIR, filename)
    with open(path) as f:
        return f.read().strip()


def load_mcq_system_prompt(
    questions_target: int = QUESTIONS_TARGET
) -> str:
    prompt = load_prompt("mcq_system.txt")

    for key, value in question_prompt_params(questions_target).items():
        prompt = prompt.replace(
            "{" + key + "}",
            str(value)
        )

    return prompt

def _last_text_block(content) -> str:
    texts = [
        block.text
        for block in content
        if getattr(block, "type", None) == "text"
    ]
    return texts[-1] if texts else ""


# ── Retry wrapper ──────────────────────────────────────────────────────────────

def with_retry(fn, label: str = "API call"):
    """Call fn() with exponential backoff. Raises on final failure."""
    for attempt in range(MAX_RETRIES):
        try:
            return fn()
        except Exception as e:
            wait = 2 ** attempt
            if attempt < MAX_RETRIES - 1:
                log.warning(f"{label} failed (attempt {attempt+1}/{MAX_RETRIES}): {e}. Retrying in {wait}s...")
                time.sleep(wait)
            else:
                log.error(f"{label} failed after {MAX_RETRIES} attempts: {e}")
                raise


# ── JSON extraction ────────────────────────────────────────────────────────────

def _collect_text_blocks(content) -> str:
    """Concatenate all text blocks from a response."""
    parts = []
    for block in content:
        if hasattr(block, "text") and block.type == "text":
            parts.append(block.text)
    return "".join(parts)


def _json_start_index(text: str) -> int:
    """Find the start index of the JSON payload, skipping preamble."""
    candidates = []
    for marker in ('{"date"', "{", "["):
        idx = text.find(marker)
        if idx != -1:
            candidates.append(idx)
    if not candidates:
        raise ValueError("No JSON object or array found in response")
    return min(candidates)


def parse_json_from_text(text: str):
    """
    Parse a JSON object or array from model output that may include preamble,
    markdown fences, or trailing commentary.
    """
    text = text.strip()
    if not text:
        raise ValueError("Empty response text")

    # Prefer content inside a fenced ```json ... ``` block when present
    fence_start = text.find("```")
    if fence_start != -1:
        after_fence = text[fence_start + 3 :]
        if after_fence.startswith("json"):
            after_fence = after_fence[4:]
        after_fence = after_fence.lstrip("\n")
        fence_end = after_fence.find("```")
        if fence_end != -1:
            text = after_fence[:fence_end].strip()
        else:
            # Truncated response — no closing fence
            text = after_fence.strip()

    start = _json_start_index(text)
    payload = text[start:]

    try:
        result, _ = json.JSONDecoder().raw_decode(payload)
        return result
    except json.JSONDecodeError as exc:
        if "Extra data" not in exc.msg:
            raise ValueError(f"Invalid JSON in response: {exc}") from exc

    # Trailing commentary after valid JSON — bracket-walk to find the end
    open_ch = payload[0]
    close_ch = "}" if open_ch == "{" else "]"
    depth = 0
    in_string = False
    escape = False
    for i, ch in enumerate(payload):
        if escape:
            escape = False
            continue
        if ch == "\\" and in_string:
            escape = True
            continue
        if ch == '"':
            in_string = not in_string
            continue
        if in_string:
            continue
        if ch == open_ch:
            depth += 1
        elif ch == close_ch:
            depth -= 1
            if depth == 0:
                return json.loads(payload[: i + 1])

    raise ValueError("Incomplete JSON in response")


def extract_json(response) -> dict:
    """
    Extract JSON from Anthropic response.
    Handles responses that may contain tool_use blocks alongside text.
    """
    return parse_json_from_text(_collect_text_blocks(response.content))


# ── Call 1: harvest topics, then 1 MCQ per topic ───────────────────────────────

def _chunk(items: list, size: int) -> list[list]:
    if size < 1:
        return [items]
    return [items[i : i + size] for i in range(0, len(items), size)]


def _messages_create(**kwargs):
    """Anthropic messages call — streaming required for long web-search runs."""
    with get_client().messages.stream(**kwargs) as stream:
        return stream.get_final_message()


def _anthropic_json(
    system_prompt: str,
    user_message: str,
    *,
    tools: Optional[list] = None,
    label: str = "API call",
    max_tokens: Optional[int] = None,
) -> dict:
    """Multi-turn Anthropic call that must return a JSON object."""
    token_budget = max_tokens or MCQ_MAX_TOKENS

    def fn():
        messages = [{"role": "user", "content": user_message}]
        max_turns = 20
        max_parse_retries = 2
        parse_retries = 0
        turn = 0
        accumulated_text = ""
        kwargs = dict(
            model=settings.MCQ_MODEL,
            max_tokens=token_budget,
            system=system_prompt,
            messages=messages,
        )
        if tools:
            kwargs["tools"] = tools

        while turn < max_turns:
            turn += 1
            log.info(f"  API turn {turn}...")
            kwargs["messages"] = messages
            response = _messages_create(**kwargs)

            block_types = [b.type for b in response.content]
            log.info(f"  Stop reason: {response.stop_reason} | Blocks: {block_types}")

            os.makedirs("logs", exist_ok=True)
            debug_path = f"logs/response_{turn}_{response.stop_reason}.json"
            try:
                serializable = []
                for block in response.content:
                    entry = {"type": block.type}
                    if hasattr(block, "text"):
                        entry["text"] = block.text
                    if hasattr(block, "name"):
                        entry["name"] = block.name
                    if hasattr(block, "input"):
                        entry["input"] = block.input
                    serializable.append(entry)
                with open(debug_path, "w") as f:
                    json.dump(serializable, f, indent=2, ensure_ascii=False)
            except Exception as ex:
                log.warning(f"  Could not save debug response: {ex}")

            turn_text = _collect_text_blocks(response.content)
            if turn_text:
                accumulated_text += turn_text

            if response.stop_reason == "end_turn":
                last = _last_text_block(response.content)
                all_text = _collect_text_blocks(response.content)
                candidates = []
                for blob in (last, all_text, accumulated_text):
                    if blob and blob.strip() and blob not in candidates:
                        candidates.append(blob)
                if not candidates:
                    raise ValueError("Model returned end_turn but no text block found")
                parsed = None
                parse_err = None
                for blob in candidates:
                    try:
                        result = parse_json_from_text(blob)
                        if isinstance(result, dict) and result:
                            parsed = result
                            break
                    except Exception as e:
                        parse_err = e
                if parsed is not None:
                    return parsed
                with open("logs/parse_failure.txt", "w", encoding="utf-8") as f:
                    f.write(candidates[0])
                if parse_retries < max_parse_retries:
                    parse_retries += 1
                    log.warning(
                        f"JSON parse failed ({parse_err}) — "
                        f"requesting correction ({parse_retries}/{max_parse_retries})"
                    )
                    messages.append({"role": "assistant", "content": response.content})
                    messages.append({
                        "role": "user",
                        "content": (
                            f"Your JSON output could not be parsed: {parse_err}\n\n"
                            "Output ONLY a single valid JSON object. "
                            "The first character must be { and the last must be }.\n"
                            "No preamble, no markdown fences, no commentary."
                        ),
                    })
                    continue
                raise parse_err or ValueError("JSON parse failed")

            if response.stop_reason == "max_tokens":
                try:
                    parsed = parse_json_from_text(accumulated_text)
                    if isinstance(parsed, dict):
                        return parsed
                except ValueError:
                    pass
                log.warning("Hit max_tokens — requesting JSON continuation")
                messages.append({"role": "assistant", "content": response.content})
                messages.append({
                    "role": "user",
                    "content": (
                        "Your JSON output was truncated. Continue exactly where you "
                        "left off. Output only the continuation — no preamble, no "
                        "markdown fences, do not repeat earlier content."
                    ),
                })
                continue

            if response.stop_reason in ("pause_turn", "tool_use"):
                messages.append({"role": "assistant", "content": response.content})
                client_tool_results = []
                for block in response.content:
                    btype = getattr(block, "type", None)
                    bname = getattr(block, "name", "")
                    log.info(f"  Tool/block: {btype} {bname}")
                    if btype == "tool_use" and bname and bname != "web_search":
                        client_tool_results.append({
                            "type": "tool_result",
                            "tool_use_id": block.id,
                            "content": "Tool executed.",
                        })
                if client_tool_results:
                    messages.append({"role": "user", "content": client_tool_results})
                continue

            raise ValueError(f"Unexpected stop_reason: {response.stop_reason}")

        raise ValueError(f"Tool use loop exceeded {max_turns} turns without final response")

    return with_retry(fn, label=label)


def load_harvest_system_prompt(questions_target: int) -> str:
    prompt = load_prompt("harvest_system.txt")
    for key, value in question_prompt_params(questions_target).items():
        prompt = prompt.replace("{" + key + "}", str(value))
    return prompt


def harvest_news_items(
    today_str: str,
    reachable_urls: list[dict],
    questions_target: int,
) -> list[dict]:
    """One search call: ranked distinct news items, no questions."""
    params = question_prompt_params(questions_target)
    url_list = "\n".join(
        f"{i+1}. {u['name']}: {u['url']}"
        for i, u in enumerate(reachable_urls)
    )
    user_message = (
        f"Target date: {today_str}.\n\n"
        f"Fetch and read these URLs:\n{url_list}\n\n"
        f"Return {params['news_items_pool']} distinct UPSC-worthy news items. "
        "Do not write MCQs.\n\n"
        "FINAL OUTPUT RULE: ONLY a JSON object. First character { last character }."
    )
    log.info(f"═══ Harvest news items ({params['news_items_pool']} wanted) ═══")
    result = _anthropic_json(
        load_harvest_system_prompt(questions_target),
        user_message,
        tools=[{"type": "web_search_20250305", "name": "web_search"}],
        label="Harvest news items",
    )
    items = result.get("news_items") or result.get("news_items_found") or []
    if not isinstance(items, list):
        raise ValueError("Harvest did not return a news_items array")
    cleaned = []
    seen = set()
    for item in items:
        if not isinstance(item, dict):
            title = str(item).strip()
            item = {"title": title, "summary": title}
        title = str(item.get("title") or "").strip()
        if not title:
            continue
        key = title.lower()
        if key in seen:
            continue
        seen.add(key)
        cleaned.append(item)
    log.info(f"Harvested {len(cleaned)} distinct news items")
    if not cleaned:
        raise ValueError("Harvest JSON had no usable news items")
    return cleaned


def _select_topics(items: list[dict], questions_target: int) -> list[dict]:
    """Pick 1 topic per question, strongest first, subject-capped."""
    max_per_subject = int(question_prompt_params(questions_target)["max_per_subject"])

    def importance(item: dict) -> int:
        try:
            return int(item.get("news_importance") or 0)
        except (TypeError, ValueError):
            return 0

    ranked = sorted(items, key=importance, reverse=True)
    selected = []
    counts: dict[str, int] = {}

    def try_add(item: dict, ignore_cap: bool) -> bool:
        subject = str(item.get("gs_subject") or item.get("subject") or "").strip()
        if not ignore_cap and subject and counts.get(subject, 0) >= max_per_subject:
            return False
        selected.append(item)
        if subject:
            counts[subject] = counts.get(subject, 0) + 1
        return True

    for item in ranked:
        if len(selected) >= questions_target:
            break
        try_add(item, ignore_cap=False)
    if len(selected) < questions_target:
        selected_ids = {id(x) for x in selected}
        for item in ranked:
            if len(selected) >= questions_target:
                break
            if id(item) in selected_ids:
                continue
            try_add(item, ignore_cap=True)
    return selected[:questions_target]


def _assign_question_types(topics: list[dict]) -> list[dict]:
    stmt, direct, factual, match = split_question_types(len(topics))
    queue = (
        ["statement-based"] * stmt
        + ["direct"] * direct
        + ["direct"] * factual
        + ["match-the-column"] * match
    )
    out = []
    for i, topic in enumerate(topics):
        item = dict(topic)
        item["requested_question_type"] = queue[i] if i < len(queue) else "direct"
        out.append(item)
    return out


def generate_mcqs(
    today_str: str,
    reachable_urls: list[dict],
    questions_target: int = QUESTIONS_TARGET,
) -> dict:
    """
    Harvest a topic list from the day's URLs, then generate exactly one
    MCQ per selected topic in batches of TOPICS_PER_GENERATE_CALL.
    """
    harvested = harvest_news_items(today_str, reachable_urls, questions_target)
    topics = _assign_question_types(_select_topics(harvested, questions_target))
    if not topics:
        raise ValueError("Harvest produced no usable news items")

    chunks = _chunk(topics, TOPICS_PER_GENERATE_CALL)
    log.info(
        f"Calling {settings.MCQ_MODEL} for {len(topics)} topics "
        f"in {len(chunks)} batch(es) of up to {TOPICS_PER_GENERATE_CALL}"
    )

    merged_questions: list[dict] = []
    for i, chunk in enumerate(chunks, start=1):
        batch_size = len(chunk)
        titles = [str(t.get("title") or t.get("topic") or "") for t in chunk]
        log.info(f"═══ Generate batch {i}/{len(chunks)} — {titles} ═══")
        user_message = (
            f"Target date: {today_str}.\n\n"
            f"Write exactly {batch_size} MCQs — one per assigned item below. "
            "Do not add topics. Do not skip an item.\n\n"
            f"ASSIGNED NEWS ITEMS:\n{json.dumps(chunk, ensure_ascii=False, indent=2)}\n\n"
            "You may web-search only to verify facts for these items.\n"
            f"Use '{today_str}' as the date field.\n\n"
            "FINAL OUTPUT RULE: ONLY a JSON object. First character { last character }."
        )
        batch_questions: list = []
        attempts = 2
        for attempt in range(1, attempts + 1):
            try:
                batch = _anthropic_json(
                    load_mcq_system_prompt(batch_size),
                    user_message,
                    tools=[{"type": "web_search_20250305", "name": "web_search"}],
                    label=f"MCQ batch {i}",
                )
            except Exception as e:
                log.error(f"Batch {i}/{len(chunks)} failed (attempt {attempt}/{attempts}): {e}")
                if attempt < attempts:
                    continue
                if not merged_questions:
                    raise
                log.warning("Keeping questions from earlier batches; skipping remaining topics in this batch")
                batch = None
                break
            raw_qs = batch.get("questions") or []
            if not isinstance(raw_qs, list):
                raw_qs = []
            if raw_qs:
                batch_questions = raw_qs
                break
            log.warning(
                f"Batch {i} returned 0 questions (attempt {attempt}/{attempts})"
            )
        if not batch_questions:
            log.error(f"Batch {i} produced no questions after {attempts} attempts")
            continue
        # Stamp assigned topic onto each question if the model omitted it.
        for qi, q in enumerate(batch_questions):
            if not isinstance(q, dict):
                continue
            src = chunk[qi] if qi < len(chunk) else chunk[-1]
            q.setdefault("topic", src.get("title"))
            q.setdefault("subject", src.get("gs_subject") or src.get("subject"))
            q.setdefault("ca_tags", src.get("ca_tags"))
            q.setdefault("news_trigger", src.get("title"))
            q.setdefault("news_summary", src.get("summary"))
            q.setdefault("source_name", src.get("source_name"))
            q.setdefault("source_url", src.get("source_url"))
            q.setdefault("news_importance", src.get("news_importance"))
            q.setdefault("fallback", src.get("fallback", False))
        merged_questions.extend(batch_questions)
        log.info(f"Batch {i} returned {len(batch_questions)} questions")

    for idx, q in enumerate(merged_questions, start=1):
        if isinstance(q, dict):
            q["id"] = idx

    news_titles = [str(t.get("title") or "").strip() for t in topics if t.get("title")]
    return {
        "date": "",
        "type": "current_affairs",
        "news_items_found": news_titles,
        "topics_covered": news_titles,
        "harvested_count": len(harvested),
        "selected_topics": topics,
        "generated_at": "",
        "questions": merged_questions,
        "prompt_version": PROMPT_VERSION,
        "generate_batches": [len(c) for c in chunks],
    }


# ── Call 2: Subtopic Classification ───────────────────────────────────────────

def classify_subtopic(question: dict, taxonomy: dict) -> str:
    """
    Classify a single question into the closest subtopic from the taxonomy.

    Args:
        question: Question dict with 'subject', 'topic', 'question' fields
        taxonomy: Full taxonomy dict loaded from taxonomy.json

    Returns:
        Exact subtopic string from taxonomy, or "General"
    """
    system_prompt = load_prompt("classify_system.txt")
    subject       = question.get("subject", "")

    if subject not in taxonomy:
        log.warning(f"Subject '{subject}' not found in taxonomy — defaulting to General")
        return "General"

    # flatten all subtopics for this subject
    subtopics_flat = [
        subtopic
        for subtopics in taxonomy[subject].values()
        for subtopic in subtopics
    ]
    subtopics_text = "\n".join(f"- {s}" for s in subtopics_flat)

    user_message = (
        f"Subject: {subject}\n"
        f"Topic: {question.get('topic', '')}\n"
        f"Question: {question.get('question', '')[:300]}\n\n"
        f"Available subtopics:\n{subtopics_text}\n\n"
        f"Return the single best matching subtopic exactly as written above."
    )

    def fn():
        response = get_client().messages.create(
            model=HAIKU_MODEL,
            max_tokens=100,
            system=system_prompt,
            messages=[{"role": "user", "content": user_message}],
        )
        return response.content[0].text.strip()

    return with_retry(fn, label=f"Classify Q{question.get('id', '?')}")


def classify_all_subtopics(questions: list[dict], taxonomy: dict) -> list[dict]:
    """
    Classify subtopics for all questions.
    Each question dict must have: id, subject, topic, question keys.
    Returns same list with subtopic added to each dict.
    """
    for q in questions:
        try:
            subtopic      = classify_subtopic(q, taxonomy)
            q["subtopic"] = subtopic
            log.info(f"  Q{q.get('id','?')} → {q.get('subject')} / {q.get('topic')} / {subtopic}")
        except Exception as e:
            q["subtopic"] = "General"
            log.warning(f"  Q{q.get('id','?')} subtopic classification failed: {e}")
    return questions


# ── Call 3: Hindi Translation ──────────────────────────────────────────────────

def translate_to_hindi(transformed_questions: list[dict]) -> list[dict]:
    """
    Translate display fields of all questions to Hindi.

    Sends only the en section of each question to minimise tokens.
    Returns a list of translated en-field dicts (same length as input).

    Args:
        transformed_questions: Output of transformer.transform_all_questions()

    Returns:
        List of dicts with translated display fields only
    """
    system_prompt = load_prompt("translate_system.txt")

    # send only the en fields — no need to send shared or hi
    en_only = [q["en"] for q in transformed_questions]

    def fn():
        with get_client().messages.stream(
            model=HAIKU_MODEL,
            max_tokens=TRANSLATE_MAX_TOKENS,
            system=system_prompt,
            messages=[{"role": "user", "content": json.dumps(en_only, ensure_ascii=False)}],
        ) as stream:
            response = stream.get_final_message()
        result = parse_json_from_text(response.content[0].text)
        # ensure we got a list back
        if not isinstance(result, list):
            raise ValueError(f"Translation returned {type(result)} instead of list")
        return result

    log.info(f"Calling {HAIKU_MODEL} for Hindi translation ({len(en_only)} questions)...")
    return with_retry(fn, label="Hindi translation")