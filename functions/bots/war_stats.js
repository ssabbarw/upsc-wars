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
    if (Number(row.connectedAtMs) < cutoffMs) continue;
    const humanEmail = String(row.humanEmail || "").toLowerCase().trim();
    if (!humanEmail) continue;
    next[id] = {
      humanEmail,
      botEmail: String(row.botEmail || "").toLowerCase().trim(),
      connectedAtMs: Number(row.connectedAtMs) || 0,
    };
  }
  return next;
}

function uniquePeople(sessions) {
  return new Set(
    Object.values(sessions)
      .map((row) => row.humanEmail)
      .filter(Boolean),
  ).size;
}

async function syncWarPeopleLast24h({ sessionId, humanEmail, botEmail } = {}) {
  const now = Date.now();
  const cutoff = now - WINDOW_MS;
  const extraId = String(sessionId || "").trim();
  const extraHuman = String(humanEmail || "").toLowerCase().trim();
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(connectionsRef());
    const sessions = pruneSessions((snap.data() || {}).sessions, cutoff);
    if (extraId && extraHuman) {
      sessions[extraId] = {
        humanEmail: extraHuman,
        botEmail: String(botEmail || "").toLowerCase().trim(),
        connectedAtMs: now,
      };
    }
    const people = uniquePeople(sessions);
    tx.set(connectionsRef(), { sessions, updatedAtMs: now });
    tx.set(
      trafficBotsRef(),
      {
        warPeopleLast24h: people,
        warPeopleLast24hUpdatedAtMs: now,
      },
      { merge: true },
    );
    return people;
  });
}

async function recordBotWarConnection({ sessionId, humanEmail, botEmail }) {
  const sid = String(sessionId || "").trim();
  const email = String(humanEmail || "").toLowerCase().trim();
  if (!sid || !email) return 0;
  return syncWarPeopleLast24h({
    sessionId: sid,
    humanEmail: email,
    botEmail,
  });
}

async function publishBotWarPeopleLast24h() {
  return syncWarPeopleLast24h();
}

module.exports = {
  recordBotWarConnection,
  publishBotWarPeopleLast24h,
};
