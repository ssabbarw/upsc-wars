const admin = require("firebase-admin");
const { istParts } = require("./time");
const { listRoster, emailsOf } = require("./roster");
const { isReservedBotEmail, isLegacyBotEmail } = require("./names");
const {
  recordBotWarConnection,
  recordBotWarCompletion,
} = require("./war_stats");

function db() {
  return admin.firestore();
}

function battlesRoot() {
  return db().collection("admin_dashboard").doc("bot_battles");
}

function sessionRef(sessionId) {
  return battlesRoot().collection("sessions").doc(sessionId);
}

function dailyRef(dateId) {
  return battlesRoot().collection("daily").doc(dateId);
}

function normalizeEmail(value) {
  return String(value || "").toLowerCase().trim();
}

function looksLikeBotEmail(email) {
  return isReservedBotEmail(email) || isLegacyBotEmail(email);
}

function findBot(roster, email) {
  const want = normalizeEmail(email);
  if (!want) return null;
  return roster.find((b) => emailsOf(b).has(want)) || null;
}

function sessionFieldsFromInput(input, now) {
  const humanEmail = normalizeEmail(input.humanEmail);
  const botEmail = normalizeEmail(input.botEmail);
  return {
    sessionId: String(input.sessionId || "").trim(),
    humanEmail,
    botEmail,
    botId: String(input.botId || "").trim(),
    direction: input.direction === "outgoing" ? "outgoing" : "incoming",
    subject: String(input.subject || "").trim(),
    humanDisplayName: String(input.humanDisplayName || "").trim(),
    botName: String(input.botName || "").trim(),
    dateId: String(input.dateId || istParts().iso),
    updatedAtMs: now,
  };
}

async function recordBotBattleJoined(input) {
  const now = Date.now();
  const fields = sessionFieldsFromInput(input, now);
  if (!fields.sessionId || !fields.humanEmail || !fields.botEmail) return null;

  await db().runTransaction(async (tx) => {
    const snap = await tx.get(sessionRef(fields.sessionId));
    const prev = snap.data() || {};
    if (Number(prev.joinedAtMs) > 0) return;

    const dayId = fields.dateId;
    const day = dailyRef(dayId);
    const userDoc = day.collection("join_users").doc(fields.humanEmail);
    const userSnap = await tx.get(userDoc);
    const dailyUpdates = {
      joins: admin.firestore.FieldValue.increment(1),
      updatedAtMs: now,
    };
    if (!userSnap.exists) {
      dailyUpdates.uniqueJoins = admin.firestore.FieldValue.increment(1);
      tx.set(userDoc, { atMs: now });
    }
    tx.set(
      sessionRef(fields.sessionId),
      {
        ...fields,
        status: prev.status === "completed" ? "completed" : "joined",
        joinedAtMs: now,
      },
      { merge: true },
    );
    tx.set(day, dailyUpdates, { merge: true });
  });

  try {
    await recordBotWarConnection({
      sessionId: fields.sessionId,
      humanEmail: fields.humanEmail,
      botEmail: fields.botEmail,
    });
  } catch (e) {
    console.error("recordBotWarConnection", fields.sessionId, e);
  }
  return { joined: true, sessionId: fields.sessionId };
}

async function recordBotBattleBotFinished({ sessionId, botEmail }) {
  const sid = String(sessionId || "").trim();
  if (!sid) return null;
  const now = Date.now();
  await sessionRef(sid).set(
    {
      botEmail: normalizeEmail(botEmail),
      botFinishedAtMs: now,
      updatedAtMs: now,
    },
    { merge: true },
  );
  return { botFinished: true, sessionId: sid };
}

async function recordBotBattleHumanSubmitted(input) {
  const now = Date.now();
  const fields = sessionFieldsFromInput(input, now);
  if (!fields.sessionId || !fields.humanEmail) return null;

  const firstCompletion = await db().runTransaction(async (tx) => {
    const snap = await tx.get(sessionRef(fields.sessionId));
    const prev = snap.data() || {};
    if (Number(prev.completedAtMs) > 0 || Number(prev.humanSubmittedAtMs) > 0) {
      return false;
    }
    const dayId = String(prev.dateId || fields.dateId);
    const day = dailyRef(dayId);
    const userDoc = day.collection("completion_users").doc(fields.humanEmail);
    const userSnap = await tx.get(userDoc);
    const dailyUpdates = {
      completions: admin.firestore.FieldValue.increment(1),
      updatedAtMs: now,
    };
    if (!userSnap.exists) {
      dailyUpdates.uniqueCompletions = admin.firestore.FieldValue.increment(1);
      tx.set(userDoc, { atMs: now });
    }
    tx.set(
      sessionRef(fields.sessionId),
      {
        ...fields,
        dateId: dayId,
        status: "completed",
        humanSubmittedAtMs: now,
        completedAtMs: now,
        joinedAtMs: Number(prev.joinedAtMs) || now,
      },
      { merge: true },
    );
    tx.set(day, dailyUpdates, { merge: true });
    return true;
  });

  if (!firstCompletion) return { completed: false, sessionId: fields.sessionId };

  try {
    await recordBotWarCompletion({
      sessionId: fields.sessionId,
      humanEmail: fields.humanEmail,
      botEmail: fields.botEmail,
    });
  } catch (e) {
    console.error("recordBotWarCompletion", fields.sessionId, e);
  }
  return { completed: true, sessionId: fields.sessionId };
}

async function onBattlePaperSubmitted(sessionId, participantId) {
  const sid = String(sessionId || "").trim();
  const participant = normalizeEmail(participantId);
  if (!sid || !participant) return null;

  const matchSnap = await db().collection("battle_matches").doc(sid).get();
  if (!matchSnap.exists) return { skipped: "match_gone" };
  const match = matchSnap.data() || {};
  if (match.battle_mode !== "human") return { skipped: "not_human_mode" };

  const hostEmail = normalizeEmail(match.host_email);
  const guestEmail = normalizeEmail(match.guest_email);
  if (!looksLikeBotEmail(hostEmail) && !looksLikeBotEmail(guestEmail)) {
    return { skipped: "no_bot" };
  }

  const roster = await listRoster();
  const hostBot = findBot(roster, hostEmail);
  const guestBot = findBot(roster, guestEmail);
  if (!hostBot && !guestBot) return { skipped: "no_bot" };
  if (hostBot && guestBot) return { skipped: "bot_vs_bot" };

  const isHostParticipant = participant === hostEmail;
  const isGuestParticipant = participant === guestEmail;
  if (!isHostParticipant && !isGuestParticipant) {
    return { skipped: "not_a_player" };
  }

  const participantBot = isHostParticipant ? hostBot : guestBot;
  if (participantBot) {
    return recordBotBattleBotFinished({
      sessionId: sid,
      botEmail: participantBot.email,
    });
  }

  const bot = hostBot || guestBot;
  const humanIsHost = Boolean(guestBot);
  return recordBotBattleHumanSubmitted({
    sessionId: sid,
    humanEmail: participant,
    botEmail: bot.email,
    botId: bot.id,
    direction: humanIsHost ? "incoming" : "outgoing",
    subject: match.subject,
    humanDisplayName: humanIsHost
      ? match.host_display_name
      : match.guest_display_name,
    botName: bot.name,
    dateId: istParts().iso,
  });
}

module.exports = {
  recordBotBattleJoined,
  recordBotBattleBotFinished,
  recordBotBattleHumanSubmitted,
  onBattlePaperSubmitted,
};
