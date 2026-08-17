"""
services/url_builder.py
Builds today's source URLs from url_patterns.json and validates reachability.
"""

import json
import logging
import requests

from datetime import date
from config.settings import URL_PATTERNS_FILE

log = logging.getLogger(__name__)


def _ordinal(day: int) -> str:
    """Convert day int to zero-padded ordinal: 1 → 01st, 6 → 06th, 11 → 11th"""
    suffix = "th" if 11 <= day <= 13 else ["th", "st", "nd", "rd", "th"][min(day % 10, 4)]
    return f"{day:02d}{suffix}"


def build_urls(target_date: date) -> list[dict]:
    """
    Build URLs for target_date from url_patterns.json.
    Only returns active patterns.

    Returns:
        List of {"name": str, "url": str}
    """
    with open(URL_PATTERNS_FILE) as f:
        patterns = json.load(f)

    urls = []
    for p in patterns:
        if not p.get("active", True):
            log.info(f"Skipping inactive source: {p['name']}")
            continue

        url = p["pattern"].format(
            year       = target_date.year,
            month      = target_date.month,
            day        = target_date.day,
            month_name = target_date.strftime("%B").lower(),
            day_ordinal= _ordinal(target_date.day),
        )
        urls.append({"name": p["name"], "url": url})
        log.info(f"Built URL for {p['name']}: {url}")

    return urls


def check_url(url: str, timeout: int = 10) -> bool:
    """Return True if URL is reachable (HTTP status < 400)."""
    headers = {"User-Agent": "UPSC-Wars-CA-Pipeline/1.0"}
    try:
        r = requests.head(url, timeout=timeout, allow_redirects=True, headers=headers)
        if r.status_code < 400:
            return True
        # Many coaching sites reject HEAD.
        r = requests.get(url, timeout=timeout, allow_redirects=True, headers=headers, stream=True)
        r.close()
        return r.status_code < 400
    except Exception as e:
        log.warning(f"URL check failed for {url}: {e}")
        return False


def validate_urls(urls: list[dict]) -> tuple[list[dict], list[dict]]:
    """
    Check all URLs and split into reachable and failed.

    Returns:
        (reachable_urls, failed_urls) — each is list of {"name", "url"}
    """
    reachable = []
    failed    = []

    for u in urls:
        if check_url(u["url"]):
            reachable.append(u)
            log.info(f"✓ Reachable: {u['name']}")
        else:
            failed.append(u)
            log.warning(f"✗ Unreachable: {u['name']} — {u['url']}")

    return reachable, failed
