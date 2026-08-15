const admin = require("firebase-admin");
const { istParts, hashString, mulberry32, randInt } = require("./time");
const { surfacedToday, getBot } = require("./roster");
const { pickQuestions, pickSubject, plannedAnswer, skillForBot } = require("./questions");
const { DEFAULT_PHOTO_URL } = require("./names");
const { enqueueJob } = require("./battles");

function db() {
  return admin.firestore();
}

function dailyDoc(dateId) {
  return db().collection("bot_state").doc(`daily_${dateId}`);
}

async function maybeQueueQotd(cfg, roster, dailyRef) {
  if (cfg.qotdPerDay <= 0) return { queued: 0 };
  const dailySnap = await dailyRef.get();
  const daily = dailySnap.data() || {};
  if ((Number(daily.qotdQueued) || 0) >= cfg.qotdPerDay) return { queued: 0 };

  const parts = istParts();
  if (parts.hour < 8) return { queued: 0 };

  const active = surfacedToday(roster, parts.iso);
  if (!active.length) return { queued: 0 };
  const rng = mulberry32(hashString(`qotd:${parts.iso}`));
  const bot = active[Math.floor(rng() * active.length)];
  const delayMs = randInt(rng, 5 * 60 * 1000, 6 * 60 * 60 * 1000);
  await enqueueJob({
    type: "qotd",
    botId: bot.id,
    runAtMs: Date.now() + delayMs,
    payload: {},
  });
  await dailyRef.set({ qotdQueued: (Number(daily.qotdQueued) || 0) + 1 }, { merge: true });
  return { queued: 1, botId: bot.id };
}

async function processQotd(job) {
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };
  const picked = pickQuestions(pickSubject(`qotd:${bot.id}:${istParts().iso}`), 1, `qotd:${job.id}`);
  if (!picked.length) return { skipped: "no_question" };
  const q = picked[0];
  await db().collection("qotd_posts").add({
    question_uuid: q.uuid,
    comment: "",
    correct_option: q.correct,
    author_email: bot.email,
    author_name: bot.name,
    author_photo_url: DEFAULT_PHOTO_URL,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    correct_count: 0,
    wrong_count: 0,
    reaction_counts: {},
    attempts: {},
    reactions: {},
  });
  return { posted: true, uuid: q.uuid };
}

async function maybeQueueOpenChallenge(cfg, roster, dailyRef) {
  const metaRef = db().collection("bot_state").doc("meta");
  const metaSnap = await metaRef.get();
  const lastAt = Number((metaSnap.data() || {}).lastOpenChallengeAtMs) || 0;
  const minGap = cfg.openChallengeEveryNDays * 24 * 60 * 60 * 1000;
  if (lastAt && Date.now() - lastAt < minGap) return { queued: 0 };

  const dailySnap = await dailyRef.get();
  const daily = dailySnap.data() || {};
  if (daily.openChallengeQueued) return { queued: 0 };

  const parts = istParts();
  if (parts.hour < 10 || parts.hour > 21) return { queued: 0 };

  const active = surfacedToday(roster, parts.iso);
  if (!active.length) return { queued: 0 };
  const rng = mulberry32(hashString(`oc:${parts.iso}`));
  if (rng() > 0.35) return { queued: 0 };
  const bot = active[Math.floor(rng() * active.length)];
  await enqueueJob({
    type: "open_challenge",
    botId: bot.id,
    runAtMs: Date.now() + randInt(rng, 2 * 60 * 1000, 40 * 60 * 1000),
    payload: {},
  });
  await dailyRef.set({ openChallengeQueued: true }, { merge: true });
  await metaRef.set({ lastOpenChallengeAtMs: Date.now() }, { merge: true });
  return { queued: 1, botId: bot.id };
}

async function processOpenChallenge(job) {
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };
  const subject = pickSubject(`oc:${bot.id}:${istParts().iso}`);
  const picked = pickQuestions(subject, 10, `oc:${job.id || bot.id}`);
  if (picked.length < 10) return { skipped: "no_questions" };
  const rng = mulberry32(hashString(`ocplay:${bot.id}:${job.id}`));
  const skill = skillForBot(bot);
  const attempts = {};
  let score = 0;
  for (const q of picked) {
    const pick = plannedAnswer(q.correct, skill, rng);
    if (pick) {
      attempts[q.uuid] = pick;
      if (pick === q.correct) score += 1;
    }
  }
  const ref = db().collection("open_challenges").doc();
  const expiresAt = admin.firestore.Timestamp.fromDate(
    new Date(Date.now() + 24 * 60 * 60 * 1000),
  );
  await ref.set({
    questions: picked.map((q) => q.uuid),
    subject,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    expires_at: expiresAt,
  });
  const creatorPayload = {
    profile: {
      email: bot.email,
      name: bot.name,
      photoURL: DEFAULT_PHOTO_URL,
    },
    attempts,
    score,
    attempted_at: admin.firestore.FieldValue.serverTimestamp(),
  };
  await ref.update(new admin.firestore.FieldPath(bot.email), creatorPayload);
  await db()
    .collection("users")
    .doc(bot.email)
    .set(
      {
        lastOnlineTime: Date.now(),
        kKeyLastOpenChallengeFloatDate: Date.now(),
        kKeyLastOpenChallengeSubject: subject,
      },
      { merge: true },
    );
  return { posted: true, id: ref.id, score };
}

module.exports = {
  dailyDoc,
  maybeQueueQotd,
  processQotd,
  maybeQueueOpenChallenge,
  processOpenChallenge,
};
