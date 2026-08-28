const admin = require("firebase-admin");
const { istParts, hashString, mulberry32, randInt } = require("./time");
const { surfacedToday, getBot, warUidFor } = require("./roster");
const { plannedAnswer, skillForBot } = require("./questions");
const { enqueueJob } = require("./battles");

const PULSES = "fomo_pulses";
const USER_STATE = "fomo_pulse_user_state";
const OPTIONS = ["a", "b", "c", "d"];
const HISTORY_LIMIT = 8;
const LOOKBACK_MS = 24 * 60 * 60 * 1000;
const WINDOW_MS = 6 * 60 * 60 * 1000;
const EXPIRE_BUFFER_MS = 30 * 60 * 1000;
const MAX_NEW_PER_PULSE = 12;

function db() {
  return admin.firestore();
}

function pulseQueueRef(pulseId) {
  return db().collection("bot_state").doc(`ca_shot_${pulseId}`);
}

function tsMs(value) {
  if (!value) return 0;
  if (typeof value.toMillis === "function") return value.toMillis();
  if (typeof value === "number" && Number.isFinite(value)) return value;
  return 0;
}

function pickOption(correct, skill, rng) {
  const pick = plannedAnswer(correct, skill, rng);
  if (pick && OPTIONS.includes(pick)) return pick;
  const c = String(correct || "a").toLowerCase().slice(0, 1);
  if (OPTIONS.includes(c) && rng() < 0.5) return c;
  const wrong = OPTIONS.filter((o) => o !== c);
  return wrong[Math.floor(rng() * wrong.length)] || "a";
}

function pickNextShotBots(roster, appearDateId, pulseId, fraction, alreadyIds) {
  const active = surfacedToday(roster, appearDateId);
  const target = Math.max(0, Math.round(active.length * fraction));
  if (target <= alreadyIds.size) return [];
  const ranked = [...active]
    .filter((b) => !alreadyIds.has(b.id))
    .sort(
      (a, b) =>
        hashString(`shot:${pulseId}:${a.id}`) -
        hashString(`shot:${pulseId}:${b.id}`),
    );
  return ranked.slice(0, Math.min(MAX_NEW_PER_PULSE, target - alreadyIds.size));
}

function scheduleAt(rng, earliest, latest) {
  if (latest <= earliest) return earliest;
  const t = rng() * rng();
  return Math.floor(earliest + t * (latest - earliest));
}

function windowForPulse(pulse, now) {
  const sentMs = tsMs(pulse.sent_at) || now;
  const expireMs = tsMs(pulse.expires_at) || sentMs + 48 * 60 * 60 * 1000;
  const hardStop = expireMs - EXPIRE_BUFFER_MS;
  if (now >= hardStop) return null;
  const earliest = Math.max(now + 60 * 1000, sentMs + 90 * 1000);
  let latest = Math.min(hardStop, sentMs + WINDOW_MS);
  if (latest <= earliest) {
    latest = Math.min(hardStop, now + 20 * 60 * 1000);
  }
  if (latest <= earliest) return null;
  return { earliest, latest };
}

async function loadRecentPulses(now) {
  const snap = await db()
    .collection(PULSES)
    .where("status", "==", "sent")
    .orderBy("sent_at", "desc")
    .limit(HISTORY_LIMIT)
    .get();
  const out = [];
  snap.forEach((doc) => {
    const pulse = { id: doc.id, ...doc.data() };
    const sentMs = tsMs(pulse.sent_at);
    if (sentMs && now - sentMs > LOOKBACK_MS) return;
    if (pulse.status !== "sent") return;
    const expireMs = tsMs(pulse.expires_at);
    if (expireMs && expireMs <= now) return;
    out.push(pulse);
  });
  return out;
}

async function maybeQueueCaShots(cfg, roster) {
  const fraction = Number(cfg.caShotFraction);
  if (!Number.isFinite(fraction) || fraction <= 0) return { queued: 0 };
  const parts = istParts();
  const now = Date.now();
  let pulses;
  try {
    pulses = await loadRecentPulses(now);
  } catch (e) {
    console.error("maybeQueueCaShots: list pulses failed", e);
    return { queued: 0, skipped: "query_failed" };
  }
  if (!pulses.length) return { queued: 0, skipped: "no_pulses" };

  let queued = 0;
  const perPulse = [];
  for (const pulse of pulses) {
    const window = windowForPulse(pulse, now);
    if (!window) continue;
    const qRef = pulseQueueRef(pulse.id);
    const qSnap = await qRef.get();
    const alreadyIds = new Set(
      (Array.isArray((qSnap.data() || {}).queuedBotIds)
        ? (qSnap.data() || {}).queuedBotIds
        : []
      ).map(String),
    );
    const bots = pickNextShotBots(
      roster,
      parts.iso,
      pulse.id,
      fraction,
      alreadyIds,
    );
    if (!bots.length) continue;
    const rng = mulberry32(
      hashString(`shotq:${pulse.id}:${alreadyIds.size}`),
    );
    for (const bot of bots) {
      await enqueueJob({
        type: "ca_shot_attempt",
        botId: bot.id,
        runAtMs: scheduleAt(rng, window.earliest, window.latest),
        payload: { pulseId: pulse.id },
      });
      alreadyIds.add(bot.id);
    }
    await qRef.set({ queuedBotIds: [...alreadyIds] }, { merge: true });
    queued += bots.length;
    perPulse.push({ pulseId: pulse.id, queued: bots.length });
  }
  return { queued, pulses: perPulse };
}

async function processCaShotAttempt(job) {
  const pulseId = String((job.payload && job.payload.pulseId) || "").trim();
  if (!pulseId) return { skipped: "no_pulse" };
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };

  const uid = warUidFor(bot);
  const pulseRef = db().collection(PULSES).doc(pulseId);
  const stateRef = db().collection(USER_STATE).doc(uid);
  const rng = mulberry32(hashString(`shotans:${pulseId}:${bot.id}`));
  const skill = skillForBot(bot);
  const timeSpent = randInt(rng, 18, 140);

  return db().runTransaction(async (tx) => {
    const pulseSnap = await tx.get(pulseRef);
    if (!pulseSnap.exists) return { skipped: "missing" };
    const pulse = pulseSnap.data() || {};
    if (pulse.status !== "sent") return { skipped: "not_active" };
    const expireMs = tsMs(pulse.expires_at);
    if (expireMs && expireMs < Date.now()) return { skipped: "expired" };

    const stateSnap = await tx.get(stateRef);
    const state = stateSnap.exists ? stateSnap.data() || {} : {};
    const attempts =
      state.attempts && typeof state.attempts === "object"
        ? { ...state.attempts }
        : {};
    if (attempts[pulseId]) return { skipped: "already" };

    const correctOpt = String(pulse.question?.shared?.correct_option || "a")
      .trim()
      .toLowerCase()
      .slice(0, 1);
    const selected = pickOption(correctOpt, skill, rng);
    const isCorrect = selected === correctOpt;

    attempts[pulseId] = {
      o: selected,
      c: isCorrect,
      t: timeSpent,
      at: admin.firestore.FieldValue.serverTimestamp(),
    };
    tx.set(
      stateRef,
      {
        attempts,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    tx.update(pulseRef, {
      attempt_count: admin.firestore.FieldValue.increment(1),
      correct_count: admin.firestore.FieldValue.increment(isCorrect ? 1 : 0),
    });
    return { attempted: true, correct: isCorrect, pulseId };
  });
}

module.exports = {
  maybeQueueCaShots,
  processCaShotAttempt,
};
