"""
services/email_service.py
Gmail SMTP — one summary email per pipeline run.
"""

import logging
import smtplib

from datetime import datetime, timedelta
from email.mime.text import MIMEText
from email.mime.multipart import MIMEMultipart
from config.settings import GMAIL_SENDER, GMAIL_APP_PASSWORD, GMAIL_RECIPIENT

log = logging.getLogger(__name__)


def _format_duration(delta: timedelta) -> str:
    total_seconds = int(delta.total_seconds())
    hours, remainder = divmod(total_seconds, 3600)
    minutes, seconds = divmod(remainder, 60)
    if hours:
        return f"{hours}h {minutes}m {seconds}s"
    if minutes:
        return f"{minutes}m {seconds}s"
    return f"{seconds}s"


def _format_timestamp(dt: datetime) -> str:
    return dt.strftime("%Y-%m-%d %H:%M:%S")


def send_email(subject: str, body: str):
    """Send email via Gmail SMTP App Password."""
    if not GMAIL_SENDER or not GMAIL_APP_PASSWORD or not GMAIL_RECIPIENT:
        log.warning("Gmail not configured — skip summary email")
        return
    try:
        msg            = MIMEMultipart()
        msg["From"]    = GMAIL_SENDER
        msg["To"]      = GMAIL_RECIPIENT
        msg["Subject"] = f"[UPSC Pipeline] {subject}"
        msg.attach(MIMEText(body, "plain"))

        with smtplib.SMTP_SSL("smtp.gmail.com", 465) as server:
            server.login(GMAIL_SENDER, GMAIL_APP_PASSWORD)
            server.send_message(msg)

        log.info(f"Summary email sent: {subject}")

    except Exception as e:
        log.error(f"Failed to send summary email '{subject}': {e}")


class PipelineReport:
    """Collects errors and warnings during a run; sends one email at the end."""

    def __init__(self, date_str: str):
        self.date_str = date_str
        self.errors: list[str] = []
        self.warnings: list[str] = []
        self.completed = False
        self.question_count = 0
        self.questions_target = 0
        self.subjects: list[str] = []
        self.reachable_sources: list[str] = []
        self.failed_sources: list[str] = []
        self.hindi_ok = False

    def add_error(self, message: str):
        self.errors.append(message)
        log.exception(message)

    def add_warning(self, message: str):
        self.warnings.append(message)
        log.warning(message)

    def mark_success(
        self,
        question_count: int,
        questions_target: int,
        subjects: list[str],
        reachable_sources: list[str],
        failed_sources: list[str],
        hindi_ok: bool,
    ):
        self.completed = True
        self.question_count = question_count
        self.questions_target = questions_target
        self.subjects = subjects
        self.reachable_sources = reachable_sources
        self.failed_sources = failed_sources
        self.hindi_ok = hindi_ok

    def send_summary(self, start: datetime, end: datetime):
        duration = _format_duration(end - start)
        timing_block = (
            f"Started:  {_format_timestamp(start)}\n"
            f"Ended:    {_format_timestamp(end)}\n"
            f"Duration: {duration}\n"
        )

        if self.errors:
            subject = f"FAILED — {self.date_str}"
            body_parts = [
                f"Daily MCQ pipeline failed for {self.date_str}.\n",
                timing_block,
                "Errors:",
            ]
            body_parts.extend(f"  {i}. {err}" for i, err in enumerate(self.errors, 1))
            if self.warnings:
                body_parts.append("\nWarnings:")
                body_parts.extend(f"  {i}. {w}" for i, w in enumerate(self.warnings, 1))
            send_email(subject, "\n".join(body_parts))
            return

        subject = f"SUCCESS — {self.date_str}"
        body_parts = [
            f"Daily MCQ pipeline completed for {self.date_str}.\n",
            timing_block,
            f"Questions:        {self.question_count}/{self.questions_target}",
            f"Subjects covered: {', '.join(self.subjects) or 'N/A'}",
            f"Sources used:     {', '.join(self.reachable_sources) or 'N/A'}",
            f"Failed URLs:      {', '.join(self.failed_sources) or 'None'}",
            f"Hindi translated: {'Yes' if self.hindi_ok else 'No'}",
            "",
            "This email is the English draft (daily_ca_drafts).",
            "The app reads live questions from daily_mcqs after auto-publish at 12:00 AM IST, if you have not published yourself.",
        ]
        if self.warnings:
            body_parts.append("\nWarnings:")
            body_parts.extend(f"  {i}. {w}" for i, w in enumerate(self.warnings, 1))
        send_email(subject, "\n".join(body_parts))
