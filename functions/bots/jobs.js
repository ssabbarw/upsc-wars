const admin = require("firebase-admin");
const { istParts } = require("./time");
const {
  listRoster,
  releaseBotBattle,
  ensureFriendlyNames,
  ensurePublicIdentities,
  publishTrafficBotIndex,
} = require("./roster");
const { planToday } = require("./growth");
const { tickPresence } = require("./presence");
const {
  processIncomingAccept,
  processOutgoingInvite,
  maybeQueueOutgoingInvites,
} = require("./battles");
const {
  dailyDoc,
  maybeQueueQotd,
  processQotd,
  maybeQueueOpenChallenge,
  processOpenChallenge,
} = require("./community");
const {
  maybeQueueDailyWar,
  processDailyWarLobby,
  processDailyWarSubmit,
} = require("./daily_war_bots");
const { readBotConfig } = require("./config");
const { publishBotWarPeopleLast24h } = require("./war_stats");

function db() {
  return admin.firestore();
}

async function processDueJobs(cfg) {
  const snap = await db()
    .collection("bot_jobs")
    .where("status", "==", "pending")
    .get();
  const now = Date.now();
  const due = snap.docs
    .map((d) => ({ id: d.id, ...d.data() }))
    .filter((j) => Number(j.runAtMs || 0) <= now)
    .sort((a, b) => Number(a.runAtMs || 0) - Number(b.runAtMs || 0));
  const results = [];
  for (const job of due) {
    try {
      let result = null;
      if (job.type === "incoming_accept") {
        result = await processIncomingAccept(job, cfg);
      } else if (job.type === "outgoing_invite") {
        result = await processOutgoingInvite(job, cfg);
      } else if (job.type === "qotd") {
        result = await processQotd(job);
      } else if (job.type === "open_challenge") {
        result = await processOpenChallenge(job);
      } else if (job.type === "daily_war_lobby") {
        result = await processDailyWarLobby(job);
      } else if (job.type === "daily_war_submit") {
        result = await processDailyWarSubmit(job);
      } else {
        result = { skipped: "unknown_type" };
      }
      await db()
        .collection("bot_jobs")
        .doc(job.id)
        .set(
          {
            status: result && result.skipped ? "skipped" : "done",
            finishedAtMs: Date.now(),
            result: result || {},
          },
          { merge: true },
        );
      results.push({ id: job.id, type: job.type, result });
    } catch (e) {
      console.error("bots.processDueJobs failed", job.id, job.type, e);
      await db()
        .collection("bot_jobs")
        .doc(job.id)
        .set(
          {
            status: "error",
            finishedAtMs: Date.now(),
            error: e && e.message ? e.message : String(e),
          },
          { merge: true },
        );
      results.push({ id: job.id, type: job.type, error: true });
    }
  }
  return results;
}

async function releaseStaleBattles(roster) {
  const now = Date.now();
  for (const bot of roster) {
    if (bot.status !== "active") continue;
    if (bot.inBattleSessionId && Number(bot.inBattleUntilMs || 0) < now) {
      await releaseBotBattle(bot.id);
      bot.inBattleSessionId = null;
    }
  }
}

async function runBotTick() {
  const cfg = await readBotConfig();
  if (!cfg.enabled) {
    return { ok: true, skipped: "disabled" };
  }
  const growth = await planToday(cfg);
  let roster = await listRoster();
  const renamed = await ensureFriendlyNames(roster);
  roster = await listRoster();
  const identities = await ensurePublicIdentities(roster);
  await releaseStaleBattles(roster);
  roster = await listRoster();
  await publishTrafficBotIndex(roster);
  try {
    await publishBotWarPeopleLast24h();
  } catch (e) {
    console.error("publishBotWarPeopleLast24h", e);
  }

  const metaSnap = await db().collection("bot_state").doc("meta").get();
  const lastPresence = Number((metaSnap.data() || {}).lastPresenceAtMs) || 0;
  const presenceDue = Date.now() - lastPresence >= cfg.tickMinutes * 60 * 1000 - 5000;
  let presence = null;
  if (presenceDue) {
    presence = await tickPresence(cfg, roster);
  }

  const dateId = istParts().iso;
  const dailyRef = dailyDoc(dateId);
  const planned = {};
  try {
    planned.qotd = await maybeQueueQotd(cfg, roster, dailyRef);
  } catch (e) {
    console.error("maybeQueueQotd", e);
  }
  try {
    planned.openChallenge = await maybeQueueOpenChallenge(cfg, roster, dailyRef);
  } catch (e) {
    console.error("maybeQueueOpenChallenge", e);
  }
  try {
    planned.outgoing = await maybeQueueOutgoingInvites(cfg, roster, dailyRef);
  } catch (e) {
    console.error("maybeQueueOutgoingInvites", e);
  }
  try {
    planned.dailyWar = await maybeQueueDailyWar(cfg, roster, dailyRef);
  } catch (e) {
    console.error("maybeQueueDailyWar", e);
  }

  const jobs = await processDueJobs(cfg);
  return {
    ok: true,
    growth,
    renamed,
    identities,
    presence,
    planned,
    jobs: jobs.length,
  };
}

module.exports = { runBotTick, processDueJobs };
