"""
Cloud Functions entry — 8:00 PM IST generate into daily_ca_drafts.

Secrets (Secret Manager): ANTHROPIC_API_KEY, GMAIL_SENDER,
GMAIL_APP_PASSWORD, GMAIL_RECIPIENT.
"""

import os

os.environ.setdefault("MCQ_MODEL", "claude-sonnet-4-6")
os.environ.setdefault("MAX_RETRIES", "3")
os.environ.setdefault("PROMPT_VERSION", "1.4")

from datetime import datetime, timedelta, timezone

from firebase_functions import scheduler_fn
from firebase_functions.options import MemoryOption, SupportedRegion

from pipeline import run

_IST = timezone(timedelta(hours=5, minutes=30))


@scheduler_fn.on_schedule(
    schedule="0 20 * * *",
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
    today = datetime.now(_IST).date()
    run(today, local=False)
