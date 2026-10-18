/**
 * Promo codes that unlock the paid Prelims Test Series for free (for example
 * one code per influencer).
 *
 * Data model (all server-written; see firestore.rules):
 *
 *  test_series_promos/{CODE}                 one doc per code
 *      seriesId, label, active, maxRedemptions|null, expiresAt|null,
 *      redemptionCount, createdAt, createdBy
 *  test_series_promos/{CODE}/redemptions/{uid}
 *      uid, email, redeemedAt   (one per user per code: this is the audit
 *      trail and also what makes redeeming idempotent)
 *  test_series_grants/{uid}                  what the app reads
 *      series: { [seriesId]: { source, code, grantedAt } }
 *  test_series_redeem_attempts/{uid}         failed-guess throttle
 *
 * A grant is permanent and tied to the Firebase uid (a real Google/Apple
 * account), so it survives reinstalls and works on every device the user
 * signs in on. Disabling or expiring a code never revokes existing grants.
 *
 * Callables:
 *  - redeemTestSeriesCode               (any real account)
 *  - adminCreateTestSeriesPromo         (admin)
 *  - adminSetTestSeriesPromoActive      (admin)
 */
const admin = require("firebase-admin");
const crypto = require("crypto");
const { onCall, HttpsError } = require("firebase-functions/v2/https");

const REGION = "asia-south1";

const PROMOS = "test_series_promos";
const GRANTS = "test_series_grants";
const ATTEMPTS = "test_series_redeem_attempts";

const MAX_FAILED_ATTEMPTS = 8;
const ATTEMPT_WINDOW_MS = 60 * 60 * 1000;

const CODE_RE = /^[A-Z0-9][A-Z0-9_-]{2,31}$/;
// No 0/O/1/I so codes read cleanly when an influencer says them out loud.
const CODE_ALPHABET = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";

const INVALID_CODE_MESSAGE = "That code isn't valid. Check it and try again.";
const EXPIRED_MESSAGE = "Code expired";
const LIMIT_REACHED_MESSAGE = "Code limit reached";

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

function randomCode(length) {
  const bytes = crypto.randomBytes(length);
  let out = "";
  for (let i = 0; i < length; i++) {
    out += CODE_ALPHABET[bytes[i] % CODE_ALPHABET.length];
  }
  return out;
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
    throw new HttpsError("invalid-argument", "The expiry date must be in the future.");
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
      throw new RedeemFailure("failed-precondition", EXPIRED_MESSAGE, false);
    }
    const max = promo.maxRedemptions;
    if (
      !redemptionSnap.exists &&
      typeof max === "number" &&
      (promo.redemptionCount || 0) >= max
    ) {
      throw new RedeemFailure(
        "failed-precondition",
        LIMIT_REACHED_MESSAGE,
        false,
      );
    }

    tx.set(
      grantRef,
      {
        series: {
          [seriesId]: {
            source: "code",
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
// Admin
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
    await ref.update({ active: data.active });
    return { ok: true };
  },
);
