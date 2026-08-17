"""
services/formatter.py

Deterministic post-processing for display text, explanations, and tables.

Firestore cannot store nested arrays, so table rows are normalized to:
  - rows: [{"List I": "...", "List II": "...", "list_i": "...", "list_ii": "..."}, ...]
  - list_i / list_ii: parallel string arrays (many clients read these directly)
  - headers: same as columns

See prompts/mcq_system.txt and services/transformer.py for the canonical schema.
"""

import logging
import re
from typing import Optional

log = logging.getLogger(__name__)

OPTION_MARKER = re.compile(r"\([a-d]\)", re.IGNORECASE)
OPTION_SPLIT = re.compile(r"(?=\([a-d]\)\s*)", re.IGNORECASE)
FIRST_OPTION = re.compile(r"\([a-d]\)\s*", re.IGNORECASE)
WHICH_LINE = re.compile(r"Which of the above", re.IGNORECASE)
NUMBERED_STMT = re.compile(r"(?<!\n)(\d+)\.\s+")
BULLET = re.compile(r"(?<!\n)(•\s+)")

LIST_I_ALIASES = frozenset({
    "list i", "list_i", "listi", "col_0", "column_0", "left", "column_a", "0",
})
LIST_II_ALIASES = frozenset({
    "list ii", "list_ii", "listii", "col_1", "column_1", "right", "column_b", "1",
})


def _literal_newlines(text: str) -> str:
    return text.replace("\\n", "\n")


def _collapse_blank_lines(text: str) -> str:
    return re.sub(r"\n{3,}", "\n\n", text).strip()


def _split_options(text: str) -> tuple[str, list[str]]:
    """Split text into stem and option strings like '(a) ...'."""
    if not FIRST_OPTION.search(text):
        return text.strip(), []

    parts = OPTION_SPLIT.split(text.strip())
    stem = parts[0].strip()
    options = [p.strip() for p in parts[1:] if p.strip()]
    return stem, options


def _join_stem_and_options(stem: str, options: list[str]) -> str:
    if not options:
        return stem
    cleaned = []
    for opt in options:
        if not opt.startswith("("):
            opt = re.sub(r"^([a-d])\)\s*", r"(\1) ", opt, flags=re.IGNORECASE)
        cleaned.append(opt.strip())
    return stem + "\n\n" + "\n".join(cleaned)


def format_display_text(text: Optional[str], question_type: str) -> Optional[str]:
    """
    Format question display text with line breaks before options.

    Each option on its own line, blank line before the first (a):
      stem\\n\\n(a) ...\\n(b) ...
    """
    if not text:
        return text

    text = _collapse_blank_lines(_literal_newlines(text))
    text = NUMBERED_STMT.sub(r"\n\1. ", text).strip()

    stem, options = _split_options(text)
    if options:
        text = _join_stem_and_options(stem, options)

    if question_type in ("multi-statement-correct", "statement-based"):
        match = WHICH_LINE.search(text)
        if match and match.start() > 0:
            before = text[: match.start()].rstrip()
            after = text[match.start() :].lstrip()
            if not before.endswith("\n\n"):
                text = before + "\n\n" + after

        match = FIRST_OPTION.search(text)
        if match and match.start() > 0:
            before = text[: match.start()].rstrip()
            after = text[match.start() :].lstrip()
            if not before.endswith("\n\n"):
                text = before + "\n\n" + after

    return text


def format_prose(text: Optional[str]) -> Optional[str]:
    """Add paragraph and bullet line breaks in explanation fields."""
    if not text:
        return text

    text = _collapse_blank_lines(_literal_newlines(text))
    text = BULLET.sub(r"\n\1", text)
    text = re.sub(
        r"(?<=[.!?])\s+(Option \([a-d]\):?)",
        r"\n\n\1",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"(?<=[.!?])\s+(\([a-d]\) (?:is|are) (?:incorrect|correct|wrong|right))",
        r"\n\n\1",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"\s+(\*\*Statement \d+|\*\*Option \([a-d]\)|Statement \d+ (?:is|are))",
        r"\n\n\1",
        text,
        flags=re.IGNORECASE,
    )
    text = re.sub(
        r"\s+(Value [Aa]ddition:?|Therefore,?|Hence,?|Thus,?|Key [Pp]oint:?)",
        r"\n\n\1",
        text,
    )
    return _collapse_blank_lines(text)


def format_footer_text(text: Optional[str]) -> Optional[str]:
    if not text:
        return text

    text = _collapse_blank_lines(_literal_newlines(text))
    stem, options = _split_options(text)
    if not options:
        return text
    return _join_stem_and_options(stem, options)


def _normalize_key(key: str) -> str:
    return re.sub(r"[\s_-]+", " ", str(key).lower()).strip()


def _parse_row_cells(row, columns: list[str]) -> list[str]:
    """Extract cell values from a row in any supported shape."""
    n = len(columns)

    if isinstance(row, (list, tuple)):
        return [str(row[i]).strip() if i < len(row) and row[i] not in (None, "") else "" for i in range(n)]

    if isinstance(row, dict):
        cells = []
        for i in range(n):
            col_name = columns[i]
            val = ""

            if col_name in row and row[col_name] not in (None, ""):
                val = str(row[col_name]).strip()
            elif f"col_{i}" in row and row[f"col_{i}"] not in (None, ""):
                val = str(row[f"col_{i}"]).strip()
            else:
                target_norm = _normalize_key(col_name)
                aliases = LIST_I_ALIASES if i == 0 else LIST_II_ALIASES
                for key, value in row.items():
                    if value in (None, ""):
                        continue
                    kn = _normalize_key(key)
                    if kn == target_norm or kn in aliases or kn == str(i):
                        val = str(value).strip()
                        break
                if not val:
                    values = [str(v).strip() for v in row.values() if v not in (None, "")]
                    if i < len(values):
                        val = values[i]
            cells.append(val)
        return cells

    if isinstance(row, str) and row.strip():
        cells = [""] * n
        cells[0] = row.strip()
        return cells

    return [""] * n


def _cell_from_row_map(row: dict, col: str, index: int) -> str:
    keys = [col, f"col_{index}"]
    if index == 0:
        keys.append("list_i")
    elif index == 1:
        keys.append("list_ii")
    for key in keys:
        val = row.get(key)
        if val not in (None, ""):
            return str(val).strip()
    return ""


def _row_to_firestore_map(cells: list[str], columns: list[str]) -> dict:
    """Build a Firestore-safe row map with column-name and list_i/list_ii keys."""
    row_map = {}
    for i, col in enumerate(columns):
        if i < len(cells):
            row_map[str(col)] = cells[i]
    if len(cells) > 0:
        row_map["list_i"] = cells[0]
    if len(cells) > 1:
        row_map["list_ii"] = cells[1]
    for i, cell in enumerate(cells):
        row_map[f"col_{i}"] = cell
    return row_map


def _parallel_lists(rows: list[dict], columns: list[str]) -> tuple[list[str], list[str]]:
    left, right = [], []
    for row in rows:
        left.append(
            row.get("list_i")
            or row.get(columns[0] if columns else "List I")
            or row.get("col_0")
            or ""
        )
        right.append(
            row.get("list_ii")
            or row.get(columns[1] if len(columns) > 1 else "List II")
            or row.get("col_1")
            or ""
        )
    return left, right


def normalize_table_data(table_data: Optional[dict]) -> Optional[dict]:
    if not table_data:
        return table_data

    columns = table_data.get("columns") or ["List I", "List II"]
    if not isinstance(columns, list) or len(columns) < 2:
        columns = ["List I", "List II"]
    columns = [str(c) for c in columns]

    raw_rows = table_data.get("rows")
    if not raw_rows:
        list_i = (
            table_data.get("list_i")
            or table_data.get("list_I")
            or table_data.get("List I")
            or []
        )
        list_ii = (
            table_data.get("list_ii")
            or table_data.get("list_II")
            or table_data.get("List II")
            or []
        )
        if list_i and list_ii:
            raw_rows = list(zip(list_i, list_ii))
        else:
            log.warning("table_data has no rows and no list_i/list_ii arrays")
            raw_rows = []

    normalized_rows = []
    for row in raw_rows:
        cells = _parse_row_cells(row, columns)
        if any(cells):
            normalized_rows.append(_row_to_firestore_map(cells, columns))

    if raw_rows and not normalized_rows:
        log.warning("table_data rows could not be normalized — all rows empty or invalid")

    result = {
        key: value
        for key, value in table_data.items()
        if key not in (
            "list_i", "list_I", "list_ii", "list_II",
            "List I", "List II",
        )
    }
    result["columns"] = columns
    result["headers"] = columns
    result["rows"] = normalized_rows
    if normalized_rows:
        list_i, list_ii = _parallel_lists(normalized_rows, columns)
        result["list_i"] = list_i
        result["list_ii"] = list_ii

    if result.get("footer_text"):
        result["footer_text"] = format_footer_text(result["footer_text"])

    return result


def merge_hi_table_from_en(en_table: Optional[dict], hi_table: Optional[dict]) -> Optional[dict]:
    """
    If Hindi translation dropped table rows, keep EN row structure and
    re-apply translated header/footer/cells where available.
    """
    en_table = normalize_table_data(en_table)
    hi_table = normalize_table_data(hi_table)

    if not en_table:
        return hi_table
    if not hi_table:
        return en_table

    en_rows = en_table.get("rows") or []
    hi_rows = hi_table.get("rows") or []

    if not en_rows:
        return hi_table

    if len(hi_rows) == len(en_rows) and hi_rows:
        return hi_table

    en_columns = en_table.get("columns") or ["List I", "List II"]
    hi_columns = hi_table.get("columns") or []
    display_columns = (
        [str(c) for c in hi_columns]
        if isinstance(hi_columns, list) and len(hi_columns) >= 2
        else en_columns
    )
    merged_rows = []
    for i, en_row in enumerate(en_rows):
        hi_row = hi_rows[i] if i < len(hi_rows) else {}
        cells = []
        for j, col in enumerate(en_columns):
            hi_val = _cell_from_row_map(hi_row, col, j) if isinstance(hi_row, dict) else ""
            en_val = _cell_from_row_map(en_row, col, j) if isinstance(en_row, dict) else ""
            cells.append(hi_val or en_val)
        merged_rows.append(_row_to_firestore_map(cells, en_columns))

    return {
        **en_table,
        **{k: v for k, v in hi_table.items() if k not in ("rows", "columns", "headers", "list_i", "list_ii")},
        "columns": display_columns,
        "headers": display_columns,
        "header_text": hi_table.get("header_text") or en_table.get("header_text", ""),
        "footer_text": hi_table.get("footer_text") or en_table.get("footer_text", ""),
        "rows": merged_rows,
        "list_i": _parallel_lists(merged_rows, en_columns)[0],
        "list_ii": _parallel_lists(merged_rows, en_columns)[1],
    }


def format_locale_section(section: Optional[dict], question_type: str) -> Optional[dict]:
    if not section:
        return section

    out = dict(section)

    if out.get("display_text"):
        out["display_text"] = format_display_text(out["display_text"], question_type)

    if out.get("table_data"):
        out["table_data"] = normalize_table_data(out["table_data"])

    for field in ("final_explanation", "upsc_trap_explanation", "strong_distractor"):
        if out.get(field):
            out[field] = format_prose(out[field])

    if out.get("elimination_logic"):
        out["elimination_logic"] = [
            format_prose(item) or item for item in out["elimination_logic"]
        ]

    if out.get("statement_analysis"):
        analysis = []
        for item in out["statement_analysis"]:
            entry = dict(item)
            if entry.get("reason"):
                entry["reason"] = format_prose(entry["reason"])
            analysis.append(entry)
        out["statement_analysis"] = analysis

    return out


def format_question(question: dict) -> dict:
    qtype = question.get("shared", {}).get("question_type", "direct")

    if question.get("en"):
        question["en"] = format_locale_section(question["en"], qtype)

    if question.get("hi"):
        en_table = (question.get("en") or {}).get("table_data")
        hi_section = format_locale_section(question["hi"], qtype)
        if hi_section and en_table:
            hi_section["table_data"] = merge_hi_table_from_en(
                en_table,
                hi_section.get("table_data"),
            )
        question["hi"] = hi_section

    meta = question.get("meta")
    if meta and meta.get("news_summary"):
        meta["news_summary"] = format_prose(meta["news_summary"])

    return question


def format_all_questions(questions: list[dict]) -> list[dict]:
    formatted = []
    for i, q in enumerate(questions):
        q = format_question(q)
        formatted.append(q)

        qtype = q.get("shared", {}).get("question_type")
        for lang in ("en", "hi"):
            td = (q.get(lang) or {}).get("table_data")
            if not td:
                continue
            row_count = len(td.get("rows") or [])
            log.info(
                f"  Q{i + 1} [{lang}] table rows: {row_count}, "
                f"list_i: {len(td.get('list_i') or [])}, list_ii: {len(td.get('list_ii') or [])}"
            )
            if qtype == "match-the-column" and row_count == 0:
                log.warning(f"  Q{i + 1} [{lang}] match-the-column table has no rows")

        for lang in ("en", "hi"):
            dt = (q.get(lang) or {}).get("display_text")
            if dt and not re.search(r"\n\([a-d]\)", dt, re.IGNORECASE):
                log.warning(f"  Q{i + 1} [{lang}] display_text missing newline before (a)")

    return formatted
