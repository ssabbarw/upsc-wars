const admin = require("firebase-admin");
const crypto = require("crypto");
const { istParts, sleep, mulberry32, hashString, randInt } = require("./time");
const {
  getBotByEmail,
  getBot,
  claimBotForBattle,
  releaseBotBattle,
  canBattleUser,
  surfacedToday,
  isBotLiveToday,
  dayStats,
  collectBotEmails,
  listRoster,
} = require("./roster");
const { upsertPresence } = require("./presence");
const {
  BATTLE_SUBJECTS,
  pickQuestions,
  pickSubject,
  correctForUuid,
  plannedAnswer,
  optionToResponseInt,
  skillForBot,
} = require("./questions");
const { recordBotBattleJoined } = require("./battle_stats");

const MAX_BODY_LEN = 180;

function db() {
  return admin.firestore();
}

function acceptDelayMs(rng) {
  const roll = rng();
  if (roll < 0.7) return randInt(rng, 60 * 1000, 8 * 60 * 1000);
  if (roll < 0.9) return randInt(rng, 20 * 60 * 1000, 90 * 60 * 1000);
  return randInt(rng, 2 * 60 * 60 * 1000, 3 * 60 * 60 * 1000);
}

async function enqueueJob(job) {
  const id = job.id || crypto.randomUUID();
  await db()
    .collection("bot_jobs")
    .doc(id)
    .set({
      ...job,
      id,
      status: "pending",
      createdAtMs: Date.now(),
    });
  return id;
}

async function relationBlocked(a, b) {
  const dbx = db();
  const [ab, ba] = await Promise.all([
    dbx.collection("users").doc(a).collection("blocked").doc(b).get(),
    dbx.collection("users").doc(b).collection("blocked").doc(a).get(),
  ]);
  return ab.exists || ba.exists;
}

/**
 * Called from sendBattleInvite when the guest is a bot.
 * Always returns { ok: true } so the host lobby behaves like a delivered push.
 */
async function handleIncomingInvite({ sessionId, hostEmail, guestEmail, cfg }) {
  const bot = await getBotByEmail(guestEmail);
  if (!bot || !isBotLiveToday(bot, istParts().iso)) {
    return { ok: true, reason: "not_a_bot" };
  }
  const dateId = istParts().iso;
  const rng = mulberry32(hashString(`incoming:${sessionId}:${bot.id}`));
  if (!canBattleUser(bot, hostEmail, dateId, cfg) || rng() > cfg.acceptRate) {
    console.log("bots.handleIncomingInvite: ignore", {
      sessionId,
      botId: bot.id,
      hostEmail,
    });
    return { ok: true, reason: "ignored" };
  }
  const delayMs = acceptDelayMs(rng);
  const appearAt = Number(bot.firstAppearAtMs || 0);
  const runAtMs = Math.max(Date.now() + delayMs, appearAt || 0);
  await enqueueJob({
    type: "incoming_accept",
    botId: bot.id,
    runAtMs,
    payload: {
      sessionId,
      hostEmail: String(hostEmail || "").toLowerCase(),
      guestEmail: bot.email,
    },
  });
  console.log("bots.handleIncomingInvite: queued", {
    sessionId,
    botId: bot.id,
    delayMs,
  });
  return { ok: true, reason: "queued" };
}

async function processIncomingAccept(job, cfg) {
  const payload = job.payload || {};
  const sessionId = payload.sessionId;
  const hostEmail = payload.hostEmail;
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };
  if (bot.appearDateId !== istParts().iso) return { skipped: "not_today" };

  const matchRef = db().collection("battle_matches").doc(sessionId);
  const matchSnap = await matchRef.get();
  if (!matchSnap.exists) return { skipped: "match_gone" };
  const match = matchSnap.data() || {};
  if (match.lets_start_game === true) return { skipped: "already_started" };
  if (match.guest_ready === true) return { skipped: "already_ready" };
  if (String(match.guest_email || "").toLowerCase() !== bot.email) {
    return { skipped: "guest_mismatch" };
  }
  if (await relationBlocked(hostEmail, bot.email)) {
    return { skipped: "blocked" };
  }

  const claimed = await claimBotForBattle(
    bot.id,
    sessionId,
    hostEmail,
    istParts().iso,
    cfg,
    "incoming",
  );
  if (!claimed.ok) return { skipped: claimed.reason };

  await matchRef.update({
    guest_ready: true,
    num_of_players_joined: 2,
  });
  await db()
    .collection("battle_matches")
    .doc(sessionId)
    .collection("joined_users")
    .doc(bot.email)
    .set(
      {
        display_name: bot.name,
        profile_pic: "no_image",
        game_progress_status: "Active",
      },
      { merge: true },
    );
  const until = Date.now() + 12 * 60 * 1000;
  await upsertPresence(bot, Date.now(), until);
  return { accepted: true, sessionId };
}

async function sendFcmBattleInvite({ guestEmail, sessionId, hostDisplayName, subjectLabel }) {
  const userSnap = await db().collection("users").doc(guestEmail).get();
  const userData = userSnap.data() || {};
  const fcmToken = userData.fcm_token || userData.fcmToken;
  if (!fcmToken || typeof fcmToken !== "string") {
    return { ok: false, reason: "no_token" };
  }
  const bodyBase = `${hostDisplayName} challenged you (${subjectLabel})`;
  const body =
    bodyBase.length > MAX_BODY_LEN
      ? `${bodyBase.slice(0, MAX_BODY_LEN - 1)}…`
      : bodyBase;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: { title: "Battle invite", body },
      data: {
        sessionId: String(sessionId),
        notification_id: `battle__${String(sessionId)}`,
        kind: "battle_join",
      },
    });
    return { ok: true };
  } catch (e) {
    console.error("bots.sendFcmBattleInvite failed", e);
    return { ok: false, reason: "send_failed" };
  }
}

async function pickOutgoingTarget(bot, dateId, cfg) {
  const path = require("./time").presenceBucketPath();
  const bucketRef = db()
    .collection("buckets")
    .doc(path.yearMonth)
    .collection(path.day)
    .doc(path.bucketId);
  const snap = await bucketRef.get();
  const data = snap.data() || {};
  const botEmails = collectBotEmails(await listRoster());
  const emails = Object.keys(data)
    .map((e) => e.toLowerCase())
    .filter((e) => e.includes("@") && !botEmails.has(e) && e !== bot.email);
  const rng = mulberry32(hashString(`out:${dateId}:${bot.id}:${Date.now()}`));
  const shuffled = [...emails];
  for (let i = shuffled.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [shuffled[i], shuffled[j]] = [shuffled[j], shuffled[i]];
  }
  for (const email of shuffled.slice(0, 12)) {
    const userSnap = await db().collection("users").doc(email).get();
    const user = userSnap.data() || {};
    if (user.acceptingBattleInvites === false) continue;
    if (!user.fcm_token && !user.fcmToken) continue;
    if (await relationBlocked(bot.email, email)) continue;
    if (!canBattleUser(bot, email, dateId, cfg)) continue;
    return {
      email,
      displayName: user.name || "UPSC Warrior",
    };
  }
  return null;
}

async function primeHumanMatch({
  sessionId,
  questionUuids,
  hostEmail,
  hostDisplayName,
  guestEmail,
  guestDisplayName,
  subject,
}) {
  const matchRef = db().collection("battle_matches").doc(sessionId);
  const emptyResponses = ListFilled(questionUuids.length);
  await matchRef.set({
    battle_mode: "human",
    host_email: hostEmail,
    host_display_name: hostDisplayName,
    guest_email: guestEmail,
    guest_display_name: guestDisplayName,
    subject,
    question_uuids: questionUuids,
    question_indexes: questionUuids.map((_, i) => i),
    lets_start_game: false,
    guest_ready: false,
    num_of_players_joined: 1,
    fcm_token: null,
  });
  const joined = matchRef.collection("joined_users");
  const over = matchRef.collection("joined_users_game_over_statuses");
  await joined.doc(hostEmail).set({
    display_name: hostDisplayName,
    profile_pic: "no_image",
    game_progress_status: "Active",
    responses: emptyResponses,
  });
  await over.doc(hostEmail).set({ game_progress_status: "Active" });
  await joined.doc(guestEmail).set({
    display_name: guestDisplayName,
    profile_pic: "no_image",
    game_progress_status: "Active",
    responses: emptyResponses,
  });
  await over.doc(guestEmail).set({ game_progress_status: "Active" });
}

function ListFilled(n) {
  return Array.from({ length: n }, () => 0);
}

async function processOutgoingInvite(job, cfg) {
  const bot = await getBot(job.botId);
  if (!bot || bot.status !== "active") return { skipped: "retired" };
  const dateId = istParts().iso;
  const target = await pickOutgoingTarget(bot, dateId, cfg);
  if (!target) return { skipped: "no_target" };

  const claimed = await claimBotForBattle(
    bot.id,
    "pending",
    target.email,
    dateId,
    cfg,
    "outgoing",
  );
  if (!claimed.ok) return { skipped: claimed.reason };

  const subject = BATTLE_SUBJECTS.includes(bot.optional)
    ? bot.optional
    : pickSubject(`${bot.id}:${dateId}`);
  const picked = pickQuestions(subject, 10, `${bot.id}:${dateId}:${target.email}`);
  if (picked.length < 10) {
    await releaseBotBattle(bot.id);
    return { skipped: "no_questions" };
  }
  const sessionId = crypto.randomUUID();
  await require("./roster").rosterCol().doc(bot.id).set(
    { inBattleSessionId: sessionId },
    { merge: true },
  );
  const uuids = picked.map((q) => q.uuid);
  await primeHumanMatch({
    sessionId,
    questionUuids: uuids,
    hostEmail: bot.email,
    hostDisplayName: bot.name,
    guestEmail: target.email,
    guestDisplayName: target.displayName,
    subject,
  });
  const fcm = await sendFcmBattleInvite({
    guestEmail: target.email,
    sessionId,
    hostDisplayName: bot.name,
    subjectLabel: subject,
  });
  if (!fcm.ok) {
    await releaseBotBattle(bot.id);
    return { skipped: fcm.reason };
  }
  const until = Date.now() + 12 * 60 * 1000;
  await upsertPresence(bot, Date.now(), until);
  return { invited: true, sessionId, guestEmail: target.email };
}

async function claimPlayLock(sessionId) {
  const matchRef = db().collection("battle_matches").doc(sessionId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(matchRef);
    if (!snap.exists) return false;
    const data = snap.data() || {};
    if (data.auto_play_started === true || data.bot_play_started === true) {
      return false;
    }
    tx.update(matchRef, { auto_play_started: true });
    return true;
  });
}

async function playAsParticipant(sessionId, participantEmail, skill) {
  const matchRef = db().collection("battle_matches").doc(sessionId);
  const matchSnap = await matchRef.get();
  if (!matchSnap.exists) return;
  const uuids = matchSnap.data().question_uuids || [];
  const joinedRef = matchRef.collection("joined_users").doc(participantEmail);
  const joinedSnap = await joinedRef.get();
  const responses = Array.isArray(joinedSnap.data() && joinedSnap.data().responses)
    ? [...joinedSnap.data().responses]
    : ListFilled(uuids.length);
  const rng = mulberry32(hashString(`play:${sessionId}:${participantEmail}`));

  for (let i = 0; i < uuids.length; i++) {
    const delay = randInt(rng, 12, 42) * 1000;
    await sleep(delay);
    const live = await matchRef.get();
    if (!live.exists) return;
    const pick = plannedAnswer(correctForUuid(uuids[i]), skill, rng);
    responses[i] = optionToResponseInt(pick);
    await joinedRef.set(
      {
        game_progress_status: "Active",
        responses,
      },
      { merge: true },
    );
  }
  await joinedRef.set({ battle_paper_submitted: true }, { merge: true });
}

async function onBattleMatchWritten(sessionId, after) {
  if (!after || after.battle_mode !== "human") return null;
  if (after.auto_play_started === true || after.bot_play_started === true) {
    return null;
  }

  const hostEmail = String(after.host_email || "").toLowerCase();
  const guestEmail = String(after.guest_email || "").toLowerCase();
  const hostBot = await getBotByEmail(hostEmail);
  const guestBot = await getBotByEmail(guestEmail);
  if (!hostBot && !guestBot) return null;

  if (hostBot && after.guest_ready === true && after.lets_start_game !== true) {
    const locked = await claimPlayLock(sessionId);
    if (!locked) return null;
    if (!guestBot) {
      try {
        await recordBotBattleJoined({
          sessionId,
          humanEmail: guestEmail,
          botEmail: hostEmail,
          botId: hostBot.id,
          direction: "outgoing",
          subject: after.subject,
          humanDisplayName: after.guest_display_name,
          botName: hostBot.name,
        });
      } catch (e) {
        console.error("recordBotBattleJoined", sessionId, e);
      }
    }
    await sleep(randInt(mulberry32(hashString(`start:${sessionId}`)), 4000, 9000));
    await db().collection("battle_matches").doc(sessionId).update({
      lets_start_game: true,
    });
    try {
      await playAsParticipant(sessionId, hostEmail, skillForBot(hostBot));
    } finally {
      await releaseBotBattle(hostBot.id);
      await upsertPresence(hostBot, Date.now(), Date.now() - 60 * 1000);
    }
    return { played: "host" };
  }

  if (guestBot && after.guest_ready === true && after.lets_start_game === true) {
    const locked = await claimPlayLock(sessionId);
    if (!locked) return null;
    if (!hostBot) {
      try {
        await recordBotBattleJoined({
          sessionId,
          humanEmail: hostEmail,
          botEmail: guestEmail,
          botId: guestBot.id,
          direction: "incoming",
          subject: after.subject,
          humanDisplayName: after.host_display_name,
          botName: guestBot.name,
        });
      } catch (e) {
        console.error("recordBotBattleJoined", sessionId, e);
      }
    }
    try {
      await playAsParticipant(sessionId, guestEmail, skillForBot(guestBot));
    } finally {
      await releaseBotBattle(guestBot.id);
      await upsertPresence(guestBot, Date.now(), Date.now() - 60 * 1000);
    }
    return { played: "guest" };
  }
  return null;
}

async function maybeQueueOutgoingInvites(cfg, roster, dailyRef) {
  const parts = istParts();
  if (parts.hour < 18 || parts.hour > 22) return { queued: 0 };
  const dailySnap = await dailyRef.get();
  const daily = dailySnap.data() || {};
  const sent = Number(daily.outgoingSent) || 0;
  if (sent >= cfg.outgoingInvitesPerDay) return { queued: 0 };
  // One attempt per evening hour so the pool stays quiet.
  const hourKey = `outgoingHour_${parts.hour}`;
  if (daily[hourKey]) return { queued: 0 };

  const onlineIds = new Set(
    ((await db().collection("bot_state").doc("meta").get()).data() || {})
      .lastOnlineBotIds || [],
  );
  const candidates = surfacedToday(roster, parts.iso).filter((b) => {
    if (!onlineIds.has(b.id) || b.inBattleSessionId) return false;
    return dayStats(b, parts.iso).battles < cfg.battlesPerDayMax;
  });
  if (!candidates.length) {
    await dailyRef.set({ [hourKey]: true }, { merge: true });
    return { queued: 0 };
  }
  const rng = mulberry32(hashString(`outq:${parts.iso}:${parts.hour}`));
  const bot = candidates[Math.floor(rng() * candidates.length)];
  await enqueueJob({
    type: "outgoing_invite",
    botId: bot.id,
    runAtMs: Date.now() + randInt(rng, 30 * 1000, 4 * 60 * 1000),
    payload: {},
  });
  await dailyRef.set(
    { [hourKey]: true, outgoingSent: sent + 1 },
    { merge: true },
  );
  return { queued: 1, botId: bot.id };
}

module.exports = {
  handleIncomingInvite,
  processIncomingAccept,
  processOutgoingInvite,
  onBattleMatchWritten,
  maybeQueueOutgoingInvites,
  enqueueJob,
};
