"""
Cloud Functions entry — generate English drafts into daily_ca_drafts.

Runs every 15 minutes. Actual generate time is
admin_dashboard/daily_ca.generate_hour_ist / generate_minute_ist (IST, default 20:00).

Admins can also call adminGenerateDailyCa when the scheduled run missed
(API quota, crash, or outside the generate window).
"""

import os
import re

os.environ.setdefault("MCQ_MODEL", "claude-sonnet-4-6")
os.environ.setdefault("MAX_RETRIES", "1")
os.environ.setdefault("PROMPT_VERSION", "1.4")
os.environ.setdefault("QUESTIONS_TARGET", "10")

from datetime import date, datetime, timedelta, timezone

from firebase_functions import https_fn, scheduler_fn
from firebase_functions.options import MemoryOption, SupportedRegion

from pipeline import run
from services.firestore import draft_exists, get_db
from services.llm import apply_firestore_llm_overrides

_IST = timezone(timedelta(hours=5, minutes=30))
_CONFIG_COL = "admin_dashboard"
_CONFIG_ID = "daily_ca"
_DEFAULT_HOUR = 20
_DEFAULT_MINUTE = 0
_WINDOW_MINUTES = 45
_STALE_LOCK_MINUTES = 50
_ISO_DATE = re.compile(r"^\d{4}-\d{2}-\d{2}$")
_ADMIN_EMAILS = {
    "sachinsabbarwal@gmail.com",
    "upscwars@gmail.com",
    "tinyminyapps@gmail.com",
    "upscmcqpractice@gmail.com",
}
_GENERATE_SECRETS = [
    "ANTHROPIC_API_KEY",
    "GMAIL_SENDER",
    "GMAIL_APP_PASSWORD",
    "GMAIL_RECIPIENT",
]


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


def _config_ref():
    return get_db().collection(_CONFIG_COL).document(_CONFIG_ID)


def _config_data() -> dict:
    snap = _config_ref().get()
    return snap.to_dict() if snap.exists else {}


def _scheduled_slot(now: datetime, data: dict) -> str:
    hour, minute = _parse_clock(data)
    return f"{now.date().isoformat()}-{hour:02d}-{minute:02d}"


def _lock_held(data: dict) -> bool:
    started = str(data.get("generate_started_slot") or "")
    started_at = str(data.get("generate_started_at") or "")
    if not started or not started_at:
        return False
    try:
        started_dt = datetime.fromisoformat(started_at.replace("Z", "+00:00"))
        age = (datetime.now(timezone.utc) - started_dt).total_seconds()
        return age < _STALE_LOCK_MINUTES * 60
    except ValueError:
        return False


def _should_run(now: datetime) -> tuple[bool, str, dict]:
    data = _config_data()
    hour, minute = _parse_clock(data)
    slot = _scheduled_slot(now, data)
    target = hour * 60 + minute
    now_mins = now.hour * 60 + now.minute
    window_end = target + _WINDOW_MINUTES
    in_window = target <= now_mins < window_end
    if not in_window:
        return False, slot, data
    if data.get("last_generate_slot") == slot:
        return False, slot, data
    if _lock_held(data):
        return False, slot, data
    return True, slot, data


def _mark_started(slot: str) -> None:
    _config_ref().set(
        {
            "generate_started_slot": slot,
            "generate_started_at": datetime.now(timezone.utc).isoformat(),
        },
        merge=True,
    )


def _mark_finished(slot: str, *, success: bool, stamp_scheduled_slot: bool) -> None:
    updates: dict = {
        "generate_started_slot": "",
        "generate_started_at": "",
    }
    if success and stamp_scheduled_slot:
        updates["last_generate_slot"] = slot
        updates["last_generate_at"] = datetime.now(timezone.utc).isoformat()
    _config_ref().set(updates, merge=True)


def _run_pipeline(target: date, slot: str, *, stamp_scheduled_slot: bool) -> dict:
    _mark_started(slot)
    print("generateDailyCa start", slot, target.isoformat())
    success = False
    try:
        if str(slot).startswith("manual-"):
            import config.settings as settings

            settings.MAX_RETRIES = max(int(settings.MAX_RETRIES or 1), 3)
        apply_firestore_llm_overrides(force=True)
        result = run(target, local=False) or {}
        success = bool(result.get("ok"))
        return result
    except Exception as e:
        print("generateDailyCa failed", slot, e)
        try:
            from services.email_service import send_email

            send_email(
                f"FAILED — Generate — {target.isoformat()}",
                f"generateDailyCa crashed:\n{e}",
            )
        except Exception as mail_err:
            print("generateDailyCa failure email failed", mail_err)
        return {
            "ok": False,
            "skipped": False,
            "date": target.isoformat(),
            "question_count": 0,
            "error": str(e),
            "reason": "crashed",
        }
    finally:
        _mark_finished(
            slot,
            success=success,
            stamp_scheduled_slot=stamp_scheduled_slot,
        )
        print("generateDailyCa done", slot, "success" if success else "failed")


def _admin_emails() -> set[str]:
    extra = os.environ.get("QUESTION_EDITOR_EMAILS") or ""
    allowed = set(_ADMIN_EMAILS)
    allowed.update(e.strip().lower() for e in extra.split(",") if e.strip())
    return allowed


def _require_admin(req: https_fn.CallableRequest) -> str:
    if req.auth is None:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.UNAUTHENTICATED,
            "Sign in required.",
        )
    token = req.auth.token or {}
    email = str(token.get("email") or "").strip().lower()
    if email not in _admin_emails():
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.PERMISSION_DENIED,
            "Admin only.",
        )
    return email


def _parse_target_date(raw: object, fallback: date) -> date:
    if raw is None:
        return fallback
    text = str(raw).strip()
    if not text:
        return fallback
    if not _ISO_DATE.match(text):
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            "date must be YYYY-MM-DD.",
        )
    try:
        return date.fromisoformat(text)
    except ValueError:
        raise https_fn.HttpsError(
            https_fn.FunctionsErrorCode.INVALID_ARGUMENT,
            "date must be YYYY-MM-DD.",
        )


@scheduler_fn.on_schedule(
    schedule="*/15 * * * *",
    timezone=scheduler_fn.Timezone("Asia/Kolkata"),
    region=SupportedRegion.ASIA_SOUTH1,
    timeout_sec=1800,
    memory=MemoryOption.GB_2,
    cpu=2,
    secrets=_GENERATE_SECRETS,
)
def generateDailyCa(event: scheduler_fn.ScheduledEvent) -> None:
    now = datetime.now(_IST)
    should, slot, _ = _should_run(now)
    if not should:
        print("generateDailyCa skip", slot, now.isoformat())
        return
    _run_pipeline(now.date(), slot, stamp_scheduled_slot=True)


@https_fn.on_call(
    region=SupportedRegion.ASIA_SOUTH1,
    timeout_sec=1800,
    memory=MemoryOption.GB_2,
    cpu=2,
    secrets=_GENERATE_SECRETS,
)
def adminGenerateDailyCa(req: https_fn.CallableRequest) -> dict:
    """Manually generate a Daily CA draft. Use when the scheduled run missed."""
    _require_admin(req)
    data = req.data if isinstance(req.data, dict) else {}
    now = datetime.now(_IST)
    target = _parse_target_date(data.get("date"), now.date())
    force = bool(data.get("force"))
    config = _config_data()
    scheduled_slot = _scheduled_slot(now, config)
    date_str = target.isoformat()

    if _lock_held(config):
        return {
            "ok": False,
            "skipped": True,
            "date": date_str,
            "question_count": 0,
            "reason": "in_progress",
            "error": "Generation is already running. Wait for the review notification.",
        }

    if target.weekday() == 6:
        return {
            "ok": True,
            "skipped": True,
            "date": date_str,
            "question_count": 0,
            "reason": "sunday",
            "error": None,
        }

    if not force and draft_exists(date_str):
        return {
            "ok": True,
            "skipped": True,
            "date": date_str,
            "question_count": 0,
            "reason": "already_exists",
            "error": None,
        }

    slot = f"manual-{date_str}"
    result = _run_pipeline(target, slot, stamp_scheduled_slot=False)
    if result.get("ok") and not result.get("skipped") and target == now.date():
        # Prevent the evening scheduler from harvesting again tonight.
        _config_ref().set(
            {
                "last_generate_slot": scheduled_slot,
                "last_generate_at": datetime.now(timezone.utc).isoformat(),
            },
            merge=True,
        )
    return result
