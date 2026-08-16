const admin = require("firebase-admin");
const { istParts, hashString, mulberry32, randInt } = require("./time");
const { surfacedToday, getBot, warUidFor } = require("./roster");
const { plannedAnswer, skillForBot } = require("./questions");
const { enqueueJob } = require("./battles");

const WARS = "daily_wars";
const RTDB_COUNTS = "daily_war_counts";

function db() {
  return admin.firestore();
}

function scoreAnswers(selectedByUuid, correctByUuid) {
  let correct = 0;
  let wrong = 0;
  let unanswered = 0;
  for (const uuid of Object.keys(correctByUuid)) {
    const selected = selectedByUuid[uuid];
    if (selected == null || String(selected).trim() === "") {
      unanswered += 1;
      continue;
    }
    if (
      String(selected).trim().toLowerCase() ===
      String(correctByUuid[uuid]).trim().toLowerCase()
    ) {
      correct += 1;
    } else {
      wrong += 1;
    }
  }
  const points = Number((correct * 2 - wrong * (2 / 3)).toFixed(2));
  return { correct, wrong, unanswered, score: points };
}

async function bumpLiveCount(dateId, field) {
  await admin
    .database()
    .ref(`${RTDB_COUNTS}/${dateId}`)
    .child(field)
    .set(admin.database.ServerValue.increment(1));
}

function pickWarBots(roster, dateId, fraction) {
  const active = surfacedToday(roster, dateId);
  const n = Math.max(0, Math.round(active.length * fraction));
  const ranked = [...active].sort(
    (a, b) => hashString(`war:${dateId}:${a.id}`) - hashString(`war:${dateId}:${b.id}`),
  );
  return ranked.slice(0, n);
}

async function maybeQueueDailyWar(cfg, roster, dailyRef) {
  const parts = istParts();
  if (parts.weekday === 0) return { queued: 0 };
  const dailySnap = await dailyRef.get();
  const daily = dailySnap.data() || {};
  const bots = pickWarBots(roster, parts.iso, cfg.dailyWarFraction);
  const out = { lobby: 0, submit: 0 };

  if (parts.hour === 20 && parts.minute >= 45 && !daily.warLobbyQueued) {
    const rng = mulberry32(hashString(`warlobby:${parts.iso}`));
    for (const bot of bots) {
      await enqueueJob({
        type: "daily_war_lobby",
        botId: bot.id,
        runAtMs: Date.now() + randInt(rng, 0, 12 * 60 * 1000),
        payload: { dateId: parts.iso },
      });
      out.lobby += 1;
    }
    await dailyRef.set({ warLobbyQueued: true }, { merge: true });
  }

  if (parts.hour === 21 && parts.minute < 15 && !daily.warSubmitQueued) {
    const rng = mulberry32(hashString(`warsub:${parts.iso}`));
    for (const bot of bots) {
      await enqueueJob({
        type: "daily_war_submit",
        botId: bot.id,
        runAtMs: Date.now() + randInt(rng, 2 * 60 * 1000, 14 * 60 * 1000),
        payload: { dateId: parts.iso },
      });
      out.submit += 1;
    }
    await dailyRef.set({ warSubmitQueued: true }, { merge: true });
  }

  return out;
}

async function processDailyWarLobby(job) {
  const dateId = (job.payload && job.payload.dateId) || istParts().iso;
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };
  const warRef = db().collection(WARS).doc(dateId);
  const presenceRef = warRef.collection("lobby_presence").doc(warUidFor(bot));
  const firstJoin = await db().runTransaction(async (tx) => {
    const warSnap = await tx.get(warRef);
    if (!warSnap.exists) return null;
    const presenceSnap = await tx.get(presenceRef);
    if (presenceSnap.exists) return false;
    tx.set(presenceRef, {
      joined_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    return true;
  });
  if (firstJoin === null) return { skipped: "no_war" };
  if (firstJoin) {
    await bumpLiveCount(dateId, "lobby");
  }
  return { joined: true, already: firstJoin === false };
}

async function processDailyWarSubmit(job) {
  const dateId = (job.payload && job.payload.dateId) || istParts().iso;
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };
  const warRef = db().collection(WARS).doc(dateId);
  const warSnap = await warRef.get();
  if (!warSnap.exists) return { skipped: "no_war" };
  const now = Date.now();
  const startMs = Date.parse(`${dateId}T21:00:00+05:30`);
  const qCount =
    warSnap.data().question_count ||
    (warSnap.data().kind === "grand" ? 25 : 15);
  const liveEndMs =
    startMs + Math.min(120, Math.max(1, Math.ceil((qCount * 80) / 60))) * 60 * 1000;
  if (now < startMs || now > liveEndMs) return { skipped: "outside_window" };

  const subRef = warRef.collection("submissions").doc(warUidFor(bot));
  const existing = await subRef.get();
  if (existing.exists) return { skipped: "already" };

  const answersSnap = await warRef.collection("private").doc("answers").get();
  if (!answersSnap.exists) return { skipped: "no_answers" };
  const correctByUuid = answersSnap.data().answers || {};
  const rng = mulberry32(hashString(`warans:${dateId}:${bot.id}`));
  const skill = skillForBot(bot);
  const answers = {};
  for (const uuid of Object.keys(correctByUuid)) {
    const pick = plannedAnswer(correctByUuid[uuid], skill, rng);
    if (pick) answers[uuid] = pick;
  }
  const breakdown = scoreAnswers(answers, correctByUuid);
  const elapsedMs = randInt(rng, 8 * 60 * 1000, Math.min(18, qCount + 3) * 60 * 1000);
  await subRef.set({
    mode: "live",
    score: breakdown.score,
    correct: breakdown.correct,
    wrong: breakdown.wrong,
    unanswered: breakdown.unanswered,
    elapsed_ms: Math.max(0, Math.min(elapsedMs, 30 * 60 * 1000)),
    answers,
    display_name: bot.name,
    streak_days: 0,
    tier_id: null,
    badges: [],
    submitted_at: admin.firestore.FieldValue.serverTimestamp(),
    submitted_at_ms: now,
  });
  try {
    await bumpLiveCount(dateId, "writing");
  } catch (e) {
    console.warn("bots.dailyWar bump writing failed", e);
  }
  return { submitted: true, score: breakdown.score };
}

module.exports = {
  maybeQueueDailyWar,
  processDailyWarLobby,
  processDailyWarSubmit,
};
