"""
services/firestore.py
Firestore read and write operations.
Single document per day — one read per user in the app.

Structure:
    daily_mcqs/{YYYY}/{MM}/{DD}

Local runs use firebase_credentials.json. Cloud Functions use ADC.
"""

import logging
import os

import firebase_admin

from datetime import date
from firebase_admin import credentials, firestore
from config.settings import (
    FIREBASE_CREDS_PATH,
    FIREBASE_PROJECT_ID,
    DAILY_COLLECTION,
    DRAFT_COLLECTION,
)

log = logging.getLogger(__name__)
_db = None


def get_db():
    """Initialise Firebase once and return Firestore client."""
    global _db
    if _db is None:
        if not firebase_admin._apps:
            creds_path = FIREBASE_CREDS_PATH
            options = {"projectId": FIREBASE_PROJECT_ID} if FIREBASE_PROJECT_ID else None
            if creds_path and os.path.isfile(creds_path):
                cred = credentials.Certificate(creds_path)
                firebase_admin.initialize_app(cred, options)
            else:
                firebase_admin.initialize_app(options=options)
        _db = firestore.client()
        log.info("Firestore initialised")
    return _db


def _doc_ref(db, target_date: date):
    """Return Firestore document reference for daily_mcqs/{YYYY}/{MM}/{DD}."""
    return (
        db.collection(DAILY_COLLECTION)
          .document(target_date.strftime("%Y"))
          .collection(target_date.strftime("%m"))
          .document(target_date.strftime("%d"))
    )


def document_exists(target_date: date) -> bool:
    """Check if document already exists for target_date."""
    db  = get_db()
    doc = _doc_ref(db, target_date).get()
    return doc.exists


def read_document(target_date: date) -> dict:
    """Load the daily MCQ document for target_date. Raises if missing."""
    db  = get_db()
    doc = _doc_ref(db, target_date).get()
    if not doc.exists:
        raise FileNotFoundError(
            f"No document at {DAILY_COLLECTION}/"
            f"{target_date.strftime('%Y')}/"
            f"{target_date.strftime('%m')}/"
            f"{target_date.strftime('%d')}"
        )
    return doc.to_dict()


def write_document(target_date: date, document: dict):
    """
    Write the merged document to Firestore.
    Overwrites if document already exists.

    Path: daily_mcqs/{YYYY}/{MM}/{DD}
    """
    db = get_db()
    _doc_ref(db, target_date).set(document)
    log.info(
        f"Written → {DAILY_COLLECTION}/"
        f"{target_date.strftime('%Y')}/"
        f"{target_date.strftime('%m')}/"
        f"{target_date.strftime('%d')}"
    )


def write_draft(content_date: str, document: dict):
    """Write English-only review draft to daily_ca_drafts/{YYYY-MM-DD}."""
    db = get_db()
    db.collection(DRAFT_COLLECTION).document(content_date).set(document)
    log.info(f"Written draft → {DRAFT_COLLECTION}/{content_date}")


def notify_admin_fcm(email: str, title: str, body: str, data: dict):
    """Send FCM to users/{email}.fcm_token if present."""
    from firebase_admin import messaging

    db = get_db()
    snap = db.collection("users").document(email.lower()).get()
    if not snap.exists:
        log.warning(f"No users/{email} doc — skip FCM")
        return
    user = snap.to_dict() or {}
    token = user.get("fcm_token") or user.get("fcmToken")
    if not token:
        log.warning(f"No FCM token for {email}")
        return

    payload = {k: str(v) for k, v in data.items()}
    msg = messaging.Message(
        token=token,
        notification=messaging.Notification(title=title, body=body),
        data=payload,
        android=messaging.AndroidConfig(priority="high"),
        apns=messaging.APNSConfig(
            payload=messaging.APNSPayload(
                aps=messaging.Aps(sound="default", badge=1),
            )
        ),
    )
    messaging.send(msg)
    log.info(f"FCM sent to {email}")