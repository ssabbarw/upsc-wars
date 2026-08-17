"""
Cloud Functions entry — generate English drafts into daily_ca_drafts.

Runs every 15 minutes. Actual generate time is
admin_dashboard/daily_ca.generate_hour_ist / generate_minute_ist (IST, default 20:00).
"""

import os

os.environ.setdefault("MCQ_MODEL", "claude-sonnet-4-6")
os.environ.setdefault("MAX_RETRIES", "3")
os.environ.setdefault("PROMPT_VERSION", "1.4")

from datetime import datetime, timedelta, timezone

from firebase_functions import scheduler_fn
from firebase_functions.options import MemoryOption, SupportedRegion

from pipeline import run
from services.firestore import get_db

_IST = timezone(timedelta(hours=5, minutes=30))
_CONFIG_COL = "admin_dashboard"
_CONFIG_ID = "daily_ca"
_DEFAULT_HOUR = 20
_DEFAULT_MINUTE = 0
_WINDOW_MINUTES = 45
_STALE_LOCK_MINUTES = 50


def _parse_clock(data: dict) -> tuple[int, int]:
    try:
        hour = int(data.get("generate_hour_ist", _DEFAULT_HOUR))
    except (TypeError, ValueError):
        hour = _DEFAULT_HOUR
    try:
        minute = int(data.get("generate_minute_ist", _DEFAULT_MINUTE))
    except (TypeError, ValueError):
        minute = _DEFAULT_MINUTE
    return max(0, min(23, hour)), max(0, min(59, minute))


def _should_run(now: datetime) -> tuple[bool, str, dict]:
    snap = get_db().collection(_CONFIG_COL).document(_CONFIG_ID).get()
    data = snap.to_dict() if snap.exists else {}
    hour, minute = _parse_clock(data)
    today = now.date().isoformat()
    slot = f"{today}-{hour:02d}-{minute:02d}"
    target = hour * 60 + minute
    now_mins = now.hour * 60 + now.minute
    window_end = target + _WINDOW_MINUTES
    in_window = target <= now_mins < window_end
    if not in_window:
        return False, slot, data
    if data.get("last_generate_slot") == slot:
        return False, slot, data
    started = str(data.get("generate_started_slot") or "")
    started_at = str(data.get("generate_started_at") or "")
    if started == slot and started_at:
        try:
            started_dt = datetime.fromisoformat(started_at.replace("Z", "+00:00"))
            age = (datetime.now(timezone.utc) - started_dt).total_seconds()
            if age < _STALE_LOCK_MINUTES * 60:
                return False, slot, data
        except ValueError:
            pass
    return True, slot, data


@scheduler_fn.on_schedule(
    schedule="*/15 * * * *",
    timezone=scheduler_fn.Timezone("Asia/Kolkata"),
    region=SupportedRegion.ASIA_SOUTH1,
    timeout_sec=1800,
    memory=MemoryOption.GB_2,
    cpu=2,
    secrets=[
        "ANTHROPIC_API_KEY",
        "GMAIL_SENDER",
        "GMAIL_APP_PASSWORD",
        "GMAIL_RECIPIENT",
    ],
)
def generateDailyCa(event: scheduler_fn.ScheduledEvent) -> None:
    now = datetime.now(_IST)
    should, slot, _ = _should_run(now)
    if not should:
        print("generateDailyCa skip", slot, now.isoformat())
        return
    ref = get_db().collection(_CONFIG_COL).document(_CONFIG_ID)
    ref.set(
        {
            "generate_started_slot": slot,
            "generate_started_at": datetime.now(timezone.utc).isoformat(),
        },
        merge=True,
    )
    print("generateDailyCa start", slot)
    run(now.date(), local=False)
    ref.set(
        {
            "last_generate_slot": slot,
            "last_generate_at": datetime.now(timezone.utc).isoformat(),
        },
        merge=True,
    )
    print("generateDailyCa done", slot)
