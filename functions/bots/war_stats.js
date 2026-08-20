const admin = require("firebase-admin");

const WINDOW_MS = 24 * 60 * 60 * 1000;

function db() {
  return admin.firestore();
}

function connectionsRef() {
  return db().collection("bot_state").doc("war_connections");
}

function trafficBotsRef() {
  return db().collection("admin_dashboard").doc("traffic_bots");
}

function pruneSessions(sessions, cutoffMs) {
  const next = {};
  for (const [id, row] of Object.entries(sessions || {})) {
    if (!row || typeof row !== "object") continue;
    const joined = Number(row.connectedAtMs) || 0;
    const completed = Number(row.completedAtMs) || 0;
    if (joined < cutoffMs && completed < cutoffMs) continue;
    const humanEmail = String(row.humanEmail || "").toLowerCase().trim();
    if (!humanEmail) continue;
    const out = {
      humanEmail,
      botEmail: String(row.botEmail || "").toLowerCase().trim(),
      connectedAtMs: joined,
    };
    if (completed > 0) out.completedAtMs = completed;
    next[id] = out;
  }
  return next;
}

function uniquePeople(sessions, { completedOnly = false, cutoffMs = 0 } = {}) {
  const emails = new Set();
  for (const row of Object.values(sessions || {})) {
    const email = String((row && row.humanEmail) || "")
      .toLowerCase()
      .trim();
    if (!email) continue;
    if (completedOnly) {
      const completed = Number(row.completedAtMs) || 0;
      if (completed < cutoffMs) continue;
    } else {
      const joined = Number(row.connectedAtMs) || 0;
      if (joined < cutoffMs) continue;
    }
    emails.add(email);
  }
  return emails.size;
}

async function syncWarPeopleLast24h({
  sessionId,
  humanEmail,
  botEmail,
  completed = false,
} = {}) {
  const now = Date.now();
  const cutoff = now - WINDOW_MS;
  const extraId = String(sessionId || "").trim();
  const extraHuman = String(humanEmail || "").toLowerCase().trim();
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(connectionsRef());
    const sessions = pruneSessions((snap.data() || {}).sessions, cutoff);
    if (extraId && extraHuman) {
      const prev = sessions[extraId] || {};
      const row = {
        humanEmail: extraHuman,
        botEmail: String(botEmail || prev.botEmail || "")
          .toLowerCase()
          .trim(),
        connectedAtMs: Number(prev.connectedAtMs) || now,
      };
      const prevCompleted = Number(prev.completedAtMs) || 0;
      if (completed) row.completedAtMs = prevCompleted || now;
      else if (prevCompleted > 0) row.completedAtMs = prevCompleted;
      sessions[extraId] = row;
    }
    const people = uniquePeople(sessions, { cutoffMs: cutoff });
    const completedPeople = uniquePeople(sessions, {
      completedOnly: true,
      cutoffMs: cutoff,
    });
    tx.set(connectionsRef(), { sessions, updatedAtMs: now });
    tx.set(
      trafficBotsRef(),
      {
        warPeopleLast24h: people,
        warPeopleLast24hUpdatedAtMs: now,
        battleCompletedPeopleLast24h: completedPeople,
        battleCompletedPeopleLast24hUpdatedAtMs: now,
      },
      { merge: true },
    );
    return { people, completedPeople };
  });
}

async function recordBotWarConnection({ sessionId, humanEmail, botEmail }) {
  const sid = String(sessionId || "").trim();
  const email = String(humanEmail || "").toLowerCase().trim();
  if (!sid || !email) return { people: 0, completedPeople: 0 };
  return syncWarPeopleLast24h({
    sessionId: sid,
    humanEmail: email,
    botEmail,
    completed: false,
  });
}

async function recordBotWarCompletion({ sessionId, humanEmail, botEmail }) {
  const sid = String(sessionId || "").trim();
  const email = String(humanEmail || "").toLowerCase().trim();
  if (!sid || !email) return { people: 0, completedPeople: 0 };
  return syncWarPeopleLast24h({
    sessionId: sid,
    humanEmail: email,
    botEmail,
    completed: true,
  });
}

async function publishBotWarPeopleLast24h() {
  return syncWarPeopleLast24h();
}

module.exports = {
  recordBotWarConnection,
  recordBotWarCompletion,
  publishBotWarPeopleLast24h,
  pruneSessions,
  uniquePeople,
};
