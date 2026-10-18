/**
 * Free access to the paid Prelims Test Series: promo codes + "free for
 * everyone" offers.
 *
 * Data model (all server-written; see firestore.rules):
 *
 *  test_series_promos/{CODE}                 one doc per code
 *      seriesId, label, kind ("code" | "open"), active, maxRedemptions|null,
 *      expiresAt|null, redemptionCount, createdAt, createdBy
 *  test_series_promos/{CODE}/redemptions/{uid}
 *      uid, email, redeemedAt   (one per user per code: this is the audit
 *      trail and also what makes redeeming idempotent)
 *  test_series_grants/{uid}                  what the app reads
 *      series: { [seriesId]: { source, code, grantedAt } }
 *  test_series_open_offer/{seriesId}         public; drives the in-app
 *      "Free for you, claim it" banner. Holds the hidden `kind: "open"` code.
 *  test_series_redeem_attempts/{uid}         failed-guess throttle
 *
 * A grant is permanent and tied to the Firebase uid (a real Google/Apple
 * account), so it survives reinstalls and works on every device the user
 * signs in on. Closing an offer or disabling a code never revokes grants.
 *
 * Callables:
 *  - redeemTestSeriesCode               (any real account)
 *  - adminCreateTestSeriesPromo         (admin)
 *  - adminSetTestSeriesPromoActive      (admin)
 *  - adminAnnounceFreeTestSeries        (admin) open offer + push
 *  - adminNotifyFreeTestSeriesOffer     (admin) re-send the push
 *  - adminCloseFreeTestSeriesOffer      (admin)
 */
const admin = require("firebase-admin");
const crypto = require("crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

const REGION = "asia-south1";

const PROMOS = "test_series_promos";
const GRANTS = "test_series_grants";
const OFFERS = "test_series_open_offer";
const ATTEMPTS = "test_series_redeem_attempts";

/** Every install subscribes to this topic; must match the broadcast topic. */
const BROADCAST_TOPIC = "upsc_wars_spot_tests";
const ANDROID_NOTIF_CHANNEL = "general_v2";
/** Must match Flutter `TestSeriesFcm.kind`. */
const FCM_KIND = "test_series_free";

const MAX_FAILED_ATTEMPTS = 8;
const ATTEMPT_WINDOW_MS = 60 * 60 * 1000;

const CODE_RE = /^[A-Z0-9][A-Z0-9_-]{2,31}$/;
// No 0/O/1/I so codes read cleanly when an influencer says them out loud.
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

const INVALID_CODE_MESSAGE = "That code isn't valid. Check it and try again.";

function db() {
  return admin.firestore();
}

function requireAdmin(request) {
  // Lazy require: avoids a circular import at cold start.
  return require("../daily_ca")._requireAdmin(request);
}

function requireRealAccount(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in to redeem a code.");
  }
  const provider =
    request.auth.token &&
    request.auth.token.firebase &&
    request.auth.token.firebase.sign_in_provider;
  if (!provider || provider === "anonymous") {
    // An anonymous uid is lost on reinstall, which would defeat the point.
    throw new HttpsError(
      "unauthenticated",
      "Sign in with Google or Apple so your access is saved to your account.",
    );
  }
  return request.auth.uid;
}

function normalizeCode(raw) {
  const code = String(raw == null ? "" : raw)
    .replace(/\s+/g, "")
    .toUpperCase();
  return CODE_RE.test(code) ? code : null;
}

function randomCode(length, prefix = "") {
  const bytes = crypto.randomBytes(length);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  }
  return `${prefix}${out}`;
}

function trimmed(raw, max) {
  return typeof raw === "string" ? raw.trim().slice(0, max) : "";
}

function parseMax(raw) {
  if (raw == null || raw === "") return null;
  const n = Number(raw);
  if (!Number.isInteger(n) || n < 1 || n > 1_000_000) {
    throw new HttpsError(
      "invalid-argument",
      "maxRedemptions must be a whole number of at least 1.",
    );
  }
  return n;
}

function parseExpiry(raw) {
  if (raw == null || raw === "") return null;
  const d = new Date(String(raw));
  if (Number.isNaN(d.getTime())) {
    throw new HttpsError("invalid-argument", "expiresAt must be an ISO date.");
  }
  if (d.getTime() <= Date.now()) {
    throw new HttpsError("invalid-argument", "expiresAt must be in the future.");
  }
  return admin.firestore.Timestamp.fromDate(d);
}

async function loadSeries(seriesId) {
  if (!seriesId) {
    throw new HttpsError("invalid-argument", "seriesId is required.");
  }
  const snap = await db().collection("test_series").doc(seriesId).get();
  if (!snap.exists) {
    throw new HttpsError("not-found", `Series "${seriesId}" does not exist.`);
  }
  return snap.data() || {};
}

// ---------------------------------------------------------------------------
// Redeeming
// ---------------------------------------------------------------------------

class RedeemFailure extends Error {
  constructor(httpsCode, message, countsAsGuess) {
    super(message);
    this.httpsCode = httpsCode;
    /** Only unknown codes count toward the throttle (that is a guess). */
    this.countsAsGuess = countsAsGuess;
  }
}

async function assertNotThrottled(uid) {
  const snap = await db().collection(ATTEMPTS).doc(uid).get();
  const d = snap.data();
  if (!d) return;
  const start = d.windowStart ? d.windowStart.toMillis() : 0;
  if (
    Date.now() - start < ATTEMPT_WINDOW_MS &&
    (d.failures || 0) >= MAX_FAILED_ATTEMPTS
  ) {
    throw new HttpsError(
      "resource-exhausted",
      "Too many wrong codes. Please try again in an hour.",
    );
  }
}

async function recordFailedGuess(uid) {
  const ref = db().collection(ATTEMPTS).doc(uid);
  await db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    const now = Date.now();
    const d = snap.data() || {};
    const start = d.windowStart ? d.windowStart.toMillis() : 0;
    if (!snap.exists || now - start >= ATTEMPT_WINDOW_MS) {
      tx.set(ref, {
        failures: 1,
        windowStart: admin.firestore.Timestamp.fromMillis(now),
      });
    } else {
      tx.update(ref, { failures: admin.firestore.FieldValue.increment(1) });
    }
  });
}

/**
 * Grants the promo's series to [uid]. Idempotent per (uid, code), and never
 * consumes a redemption when the user already owns the series.
 *
 * @returns {{status: "redeemed" | "already_owned", seriesId: string}}
 */
async function redeemCode({ uid, email, code }) {
  const promoRef = db().collection(PROMOS).doc(code);
  const redemptionRef = promoRef.collection("redemptions").doc(uid);
  const grantRef = db().collection(GRANTS).doc(uid);

  return db().runTransaction(async (tx) => {
    // All reads first.
    const [promoSnap, redemptionSnap, grantSnap] = await Promise.all([
      tx.get(promoRef),
      tx.get(redemptionRef),
      tx.get(grantRef),
    ]);

    const promo = promoSnap.data();
    if (!promoSnap.exists || !promo || promo.active !== true) {
      throw new RedeemFailure("not-found", INVALID_CODE_MESSAGE, true);
    }
    const seriesId = promo.seriesId;
    const owned =
      grantSnap.exists &&
      grantSnap.data().series &&
      grantSnap.data().series[seriesId];

    if (owned) {
      return { status: "already_owned", seriesId };
    }
    if (promo.expiresAt && promo.expiresAt.toMillis() <= Date.now()) {
      throw new RedeemFailure(
        "failed-precondition",
        "This code has expired.",
        false,
      );
    }
    const max = promo.maxRedemptions;
    if (
      !redemptionSnap.exists &&
      typeof max === "number" &&
      (promo.redemptionCount || 0) >= max
    ) {
      throw new RedeemFailure(
        "failed-precondition",
        "This code has been fully redeemed.",
        false,
      );
    }

    tx.set(
      grantRef,
      {
        series: {
          [seriesId]: {
            source: promo.kind === "open" ? "open_offer" : "code",
            code,
            grantedAt: admin.firestore.FieldValue.serverTimestamp(),
          },
        },
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (!redemptionSnap.exists) {
      tx.set(redemptionRef, {
        uid,
        email,
        seriesId,
        redeemedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      tx.update(promoRef, {
        redemptionCount: admin.firestore.FieldValue.increment(1),
        lastRedeemedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
    return { status: "redeemed", seriesId };
  });
}

exports.redeemTestSeriesCode = onCall({ region: REGION }, async (request) => {
  const uid = requireRealAccount(request);
  const email = String(request.auth.token.email || "")
    .trim()
    .toLowerCase();
  await assertNotThrottled(uid);

  const code = normalizeCode(request.data && request.data.code);
  try {
    if (!code) throw new RedeemFailure("not-found", INVALID_CODE_MESSAGE, true);
    const result = await redeemCode({ uid, email, code });
    console.log("redeemTestSeriesCode", { uid, code, status: result.status });
    return { ok: true, ...result };
  } catch (e) {
    if (e instanceof RedeemFailure) {
      if (e.countsAsGuess) await recordFailedGuess(uid);
      throw new HttpsError(e.httpsCode, e.message);
    }
    throw e;
  }
});

// ---------------------------------------------------------------------------
// Admin: codes
// ---------------------------------------------------------------------------

exports.adminCreateTestSeriesPromo = onCall(
  { region: REGION },
  async (request) => {
    const adminEmail = requireAdmin(request);
    const data = request.data || {};
    const seriesId = trimmed(data.seriesId, 80);
    await loadSeries(seriesId);

    const label = trimmed(data.label, 80);
    if (!label) {
      throw new HttpsError(
        "invalid-argument",
        "Add a label (for example the influencer's name).",
      );
    }
    let code = null;
    if (data.code != null && String(data.code).trim() !== "") {
      code = normalizeCode(data.code);
      if (!code) {
        throw new HttpsError(
          "invalid-argument",
          "Codes are 3-32 characters: letters, digits, - or _.",
        );
      }
    }
    const maxRedemptions = parseMax(data.maxRedemptions);
    const expiresAt = parseExpiry(data.expiresAt);

    // Generated codes retry on the (very unlikely) collision; custom codes
    // fail loudly instead of overwriting.
    for (let attempt = 0; attempt < 5; attempt++) {
      const candidate = code || randomCode(8);
      try {
        await db()
          .collection(PROMOS)
          .doc(candidate)
          .create({
            seriesId,
            label,
            kind: "code",
            active: true,
            maxRedemptions,
            expiresAt,
            redemptionCount: 0,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            createdBy: adminEmail,
          });
        return { ok: true, code: candidate };
      } catch (e) {
        const exists = e && (e.code === 6 || /ALREADY_EXISTS/.test(String(e)));
        if (!exists) throw e;
        if (code) {
          throw new HttpsError("already-exists", `"${code}" is already taken.`);
        }
      }
    }
    throw new HttpsError("internal", "Could not generate a unique code.");
  },
);

exports.adminSetTestSeriesPromoActive = onCall(
  { region: REGION },
  async (request) => {
    requireAdmin(request);
    const data = request.data || {};
    const code = normalizeCode(data.code);
    if (!code || typeof data.active !== "boolean") {
      throw new HttpsError("invalid-argument", "code and active are required.");
    }
    const ref = db().collection(PROMOS).doc(code);
    const snap = await ref.get();
    if (!snap.exists) throw new HttpsError("not-found", "No such code.");
    if (snap.data().kind === "open") {
      throw new HttpsError(
        "failed-precondition",
        "This is an everyone offer. Stop it from the offer card instead.",
      );
    }
    await ref.update({ active: data.active });
    return { ok: true };
  },
);

// ---------------------------------------------------------------------------
// Admin: free for everyone
// ---------------------------------------------------------------------------

async function activeOfferFor(seriesId) {
  const snap = await db().collection(OFFERS).doc(seriesId).get();
  const offer = snap.data();
  return offer && offer.active === true ? offer : null;
}

async function sendOfferPush({ seriesId, title, body, adminEmail }) {
  const notificationId = crypto.randomUUID();
  const message = {
    topic: BROADCAST_TOPIC,
    notification: { title, body },
    data: {
      kind: FCM_KIND,
      series_id: seriesId,
      notification_id: notificationId,
    },
    android: {
      priority: "high",
      notification: { channelId: ANDROID_NOTIF_CHANNEL, sound: "default" },
    },
    apns: { payload: { aps: { sound: "default" } } },
  };
  // Same bookkeeping as sendBroadcastAnnouncement so opens show up on the
  // admin dashboard.
  await db()
    .collection("admin_dashboard")
    .doc("notifications")
    .collection("items")
    .doc(notificationId)
    .set(
      {
        kind: FCM_KIND,
        title,
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
        opens: 0,
        conversions: 0,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
        created_by: adminEmail,
        target: "broadcast",
      },
      { merge: true },
    );
  await admin.messaging().send(message);
  await db().collection(OFFERS).doc(seriesId).set(
    {
      notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      lastNotificationId: notificationId,
    },
    { merge: true },
  );
  return notificationId;
}

function offerCopy(series, data) {
  const seriesTitle = trimmed(series.title, 80) || "Prelims Test Series";
  return {
    title: trimmed(data.title, 120) || `${seriesTitle} is free for you`,
    body:
      trimmed(data.body, 180) ||
      "Every test is unlocked for you, no payment needed. Tap to claim it.",
  };
}

exports.adminAnnounceFreeTestSeries = onCall(
  { region: REGION },
  async (request) => {
    const adminEmail = requireAdmin(request);
    const data = request.data || {};
    const seriesId = trimmed(data.seriesId, 80);
    const series = await loadSeries(seriesId);
    const notify = data.notify !== false;
    const maxRedemptions = parseMax(data.maxRedemptions);
    const expiresAt = parseExpiry(data.expiresAt);
    const { title, body } = offerCopy(series, data);

    // Only one open offer per series: retire the previous campaign's code
    // (its redemptions and everyone's grants stay).
    const previous = await activeOfferFor(seriesId);
    if (previous && previous.promoCode) {
      await db()
        .collection(PROMOS)
        .doc(previous.promoCode)
        .set({ active: false }, { merge: true });
    }

    const code = randomCode(6, "FREE-");
    const dateLabel = new Date().toLocaleDateString("en-IN", {
      timeZone: "Asia/Kolkata",
      day: "numeric",
      month: "short",
      year: "numeric",
    });
    await db()
      .collection(PROMOS)
      .doc(code)
      .create({
        seriesId,
        label: `Free for everyone (${dateLabel})`,
        kind: "open",
        active: true,
        maxRedemptions,
        expiresAt,
        redemptionCount: 0,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        createdBy: adminEmail,
      });
    await db().collection(OFFERS).doc(seriesId).set({
      seriesId,
      active: true,
      promoCode: code,
      title,
      body,
      expiresAt,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: adminEmail,
      notifiedAt: null,
    });

    if (!notify) return { ok: true, code, notified: false };
    try {
      const notificationId = await sendOfferPush({
        seriesId,
        title,
        body,
        adminEmail,
      });
      return { ok: true, code, notified: true, notificationId };
    } catch (e) {
      // The offer is live; the admin can retry the push separately.
      console.error("adminAnnounceFreeTestSeries: push failed", e);
      return { ok: true, code, notified: false, pushError: String(e.message || e) };
    }
  },
);

exports.adminNotifyFreeTestSeriesOffer = onCall(
  { region: REGION },
  async (request) => {
    const adminEmail = requireAdmin(request);
    const seriesId = trimmed((request.data || {}).seriesId, 80);
    const series = await loadSeries(seriesId);
    const offer = await activeOfferFor(seriesId);
    if (!offer) {
      throw new HttpsError("failed-precondition", "No active offer to announce.");
    }
    const { title, body } = offerCopy(series, offer);
    try {
      const notificationId = await sendOfferPush({
        seriesId,
        title,
        body,
        adminEmail,
      });
      return { ok: true, notificationId };
    } catch (e) {
      console.error("adminNotifyFreeTestSeriesOffer: push failed", e);
      throw new HttpsError("unavailable", `Push failed: ${e.message || e}`);
    }
  },
);

exports.adminCloseFreeTestSeriesOffer = onCall(
  { region: REGION },
  async (request) => {
    requireAdmin(request);
    const seriesId = trimmed((request.data || {}).seriesId, 80);
    if (!seriesId) {
      throw new HttpsError("invalid-argument", "seriesId is required.");
    }
    const offer = await activeOfferFor(seriesId);
    if (!offer) return { ok: true, closed: false };
    if (offer.promoCode) {
      await db()
        .collection(PROMOS)
        .doc(offer.promoCode)
        .set({ active: false }, { merge: true });
    }
    await db()
      .collection(OFFERS)
      .doc(seriesId)
      .set({ active: false, closedAt: admin.firestore.FieldValue.serverTimestamp() }, { merge: true });
    return { ok: true, closed: true };
  },
);
