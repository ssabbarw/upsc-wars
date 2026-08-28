const admin = require("firebase-admin");
const { istParts, hashString, mulberry32, randInt } = require("./time");
const { surfacedToday, getBot, warUidFor } = require("./roster");
const { plannedAnswer, skillForBot } = require("./questions");
const { enqueueJob } = require("./battles");

const DAYS = "daily_ca_days";
const MAX_ELAPSED_MS = 2 * 60 * 60 * 1000;
const FREEZE_BUFFER_MS = 45 * 60 * 1000;

function db() {
  return admin.firestore();
}

function dailyDoc(dateId) {
  return db().collection("bot_state").doc(`daily_${dateId}`);
}

function dayRef(dateId) {
  return db().collection(DAYS).doc(dateId);
}

function addDaysIso(iso, days) {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + days));
  return `${dt.getUTCFullYear()}-${String(dt.getUTCMonth() + 1).padStart(2, "0")}-${String(dt.getUTCDate()).padStart(2, "0")}`;
}

function isSundayIso(iso) {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay() === 0;
}

/** True once the paper quiz is open (next morning 6:00 AM IST). */
function isLive(iso, parts = istParts()) {
  const opensIso = addDaysIso(iso, 1);
  return parts.iso > opensIso || (parts.iso === opensIso && parts.hour >= 6);
}

/** Matches Flutter DailyCaSchedule.paperQuizContentDate. */
function paperQuizContentIso(parts = istParts()) {
  let cursor = addDaysIso(parts.iso, -1);
  for (let i = 0; i < 9; i++) {
    if (!isSundayIso(cursor) && isLive(cursor, parts)) {
      return cursor;
    }
    cursor = addDaysIso(cursor, -1);
  }
  return null;
}

function nextContentIso(iso) {
  let cursor = addDaysIso(iso, 1);
  for (let i = 0; i < 9; i++) {
    if (!isSundayIso(cursor)) return cursor;
    cursor = addDaysIso(cursor, 1);
  }
  return addDaysIso(iso, 1);
}

/** 6 AM IST on the morning this paper stops being today's quiz. */
function freezeMsForContent(dateId) {
  const next = nextContentIso(dateId);
  const opensNext = addDaysIso(next, 1);
  return Date.parse(`${opensNext}T06:00:00+05:30`);
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

function percentileFor(air, n) {
  return n <= 1 ? 100 : Number((((n - air) / (n - 1)) * 100).toFixed(2));
}

function rowSort(a, b) {
  if (b.score !== a.score) return b.score - a.score;
  return a.elapsed_ms - b.elapsed_ms;
}

function insertLeaderboardTop(top, row, n) {
  const next = (Array.isArray(top) ? top : [])
    .filter((e) => e && e.uid !== row.uid)
    .map((e) => ({ ...e }));
  next.push(row);
  next.sort(rowSort);
  const trimmed = next.slice(0, 100);
  trimmed.forEach((e, i) => {
    e.air = i + 1;
    e.percentile = percentileFor(e.air, n);
  });
  return trimmed;
}

function pickNextCaBots(roster, appearDateId, fraction, alreadyIds) {
  const active = surfacedToday(roster, appearDateId);
  const target = Math.max(0, Math.round(active.length * fraction));
  const already = alreadyIds.size;
  if (target <= already) return [];
  const ranked = [...active]
    .filter((b) => !alreadyIds.has(b.id))
    .sort(
      (a, b) =>
        hashString(`ca:${appearDateId}:${a.id}`) -
        hashString(`ca:${appearDateId}:${b.id}`),
    );
  return ranked.slice(0, target - already);
}

function scheduleAt(rng, earliest, latest) {
  if (latest <= earliest) return earliest;
  const t = rng() * rng();
  return Math.floor(earliest + t * (latest - earliest));
}

async function maybeQueueDailyCa(cfg, roster) {
  const fraction = Number(cfg.dailyCaFraction);
  if (!Number.isFinite(fraction) || fraction <= 0) return { queued: 0 };
  const parts = istParts();
  const dateId = paperQuizContentIso(parts);
  if (!dateId) return { queued: 0, skipped: "no_paper" };

  const answersSnap = await dayRef(dateId).collection("private").doc("answers").get();
  const answers = answersSnap.exists ? answersSnap.data() || {} : {};
  if (!answers.answers || !Object.keys(answers.answers).length) {
    return { queued: 0, skipped: "no_answers" };
  }

  const freezeMs = freezeMsForContent(dateId);
  const latest = freezeMs - FREEZE_BUFFER_MS;
  if (Date.now() >= latest) return { queued: 0, skipped: "too_late" };

  const caDailyRef = dailyDoc(dateId);
  const dailySnap = await caDailyRef.get();
  const daily = dailySnap.data() || {};
  const alreadyIds = new Set(
    (Array.isArray(daily.caQueuedBotIds) ? daily.caQueuedBotIds : []).map(String),
  );

  const bots = pickNextCaBots(roster, parts.iso, fraction, alreadyIds);
  if (!bots.length) return { queued: 0, dateId };

  const earliest = Date.now() + 2 * 60 * 1000;
  const rng = mulberry32(hashString(`caqueue:${dateId}:${alreadyIds.size}`));
  for (const bot of bots) {
    await enqueueJob({
      type: "daily_ca_submit",
      botId: bot.id,
      runAtMs: scheduleAt(rng, earliest, latest),
      payload: { dateId },
    });
    alreadyIds.add(bot.id);
  }
  await caDailyRef.set(
    { caQueuedBotIds: [...alreadyIds] },
    { merge: true },
  );
  return { queued: bots.length, dateId };
}

async function processDailyCaSubmit(job) {
  const dateId = (job.payload && job.payload.dateId) || paperQuizContentIso();
  if (!dateId) return { skipped: "no_paper" };
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };

  const current = paperQuizContentIso();
  if (current !== dateId) return { skipped: "not_live" };

  const uid = warUidFor(bot);
  const ref = dayRef(dateId);
  const subRef = ref.collection("submissions").doc(uid);
  const lbRef = ref.collection("meta").doc("leaderboard");
  const answersSnap = await ref.collection("private").doc("answers").get();
  if (!answersSnap.exists) return { skipped: "no_answers" };
  const correctByUuid = answersSnap.data().answers || {};
  if (!Object.keys(correctByUuid).length) return { skipped: "no_answers" };

  const rng = mulberry32(hashString(`caans:${dateId}:${bot.id}`));
  const skill = skillForBot(bot);
  const answers = {};
  for (const uuid of Object.keys(correctByUuid)) {
    const pick = plannedAnswer(correctByUuid[uuid], skill, rng);
    if (pick) answers[uuid] = pick;
  }
  const breakdown = scoreAnswers(answers, correctByUuid);
  const qCount = Array.isArray(answersSnap.data().uuids)
    ? answersSnap.data().uuids.length
    : Object.keys(correctByUuid).length;
  const elapsedMs = Math.max(
    0,
    Math.min(
      MAX_ELAPSED_MS,
      randInt(rng, 3 * 60 * 1000, Math.min(22, Math.max(8, qCount + 4)) * 60 * 1000),
    ),
  );
  const now = Date.now();

  return db().runTransaction(async (tx) => {
    const existingSnap = await tx.get(subRef);
    const lbSnap = await tx.get(lbRef);
    const existing = existingSnap.exists ? existingSnap.data() || {} : null;
    if (existing && existing.mode === "live") {
      return { skipped: "already" };
    }

    const lb = lbSnap.exists ? lbSnap.data() || {} : {};
    if (lb.status === "frozen") return { skipped: "frozen" };

    let participantCount =
      typeof lb.participant_count === "number" ? lb.participant_count : 0;
    participantCount += 1;
    const row = {
      uid,
      display_name: bot.name || "",
      score: breakdown.score,
      elapsed_ms: elapsedMs,
      correct: breakdown.correct,
      wrong: breakdown.wrong,
      unanswered: breakdown.unanswered,
    };
    const top = insertLeaderboardTop(lb.top, row, participantCount);
    tx.set(lbRef, {
      top,
      participant_count: participantCount,
      question_count: qCount || lb.question_count || 0,
      status: "live",
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    });
    tx.set(subRef, {
      mode: "live",
      score: breakdown.score,
      correct: breakdown.correct,
      wrong: breakdown.wrong,
      unanswered: breakdown.unanswered,
      elapsed_ms: elapsedMs,
      answers,
      display_name: bot.name || "",
      submitted_at: admin.firestore.FieldValue.serverTimestamp(),
      submitted_at_ms: now,
    });
    return { submitted: true, score: breakdown.score, dateId };
  });
}

module.exports = {
  maybeQueueDailyCa,
  processDailyCaSubmit,
  paperQuizContentIso,
};
