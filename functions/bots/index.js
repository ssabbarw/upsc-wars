const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const { readBotConfig } = require("./config");
const { planToday } = require("./growth");
const { runBotTick } = require("./jobs");
const { handleIncomingInvite, onBattleMatchWritten } = require("./battles");
const { onBattlePaperSubmitted } = require("./battle_stats");
const { getBotByEmail } = require("./roster");

const REGION = "asia-south1";

const ADMIN_EMAILS = new Set(
  [
    "sachinsabbarwal@gmail.com",
    "upscwars@gmail.com",
    "tinyminyapps@gmail.com",
    "upscmcqpractice@gmail.com",
    ...String(process.env.QUESTION_EDITOR_EMAILS || "")
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  ].map((e) => e.toLowerCase()),
);

function assertAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const email = (request.auth.token.email || "").toLowerCase().trim();
  if (!ADMIN_EMAILS.has(email)) {
    throw new HttpsError("permission-denied", "Admin only.");
  }
}

async function handleIncomingInviteIfBot({ sessionId, hostEmail, guestEmail }) {
  const email = String(guestEmail || "").toLowerCase();
  const bot = await getBotByEmail(email);
  if (!bot) return null;
  const cfg = await readBotConfig();
  if (!cfg.enabled) return { ok: true, reason: "bots_disabled" };
  return handleIncomingInvite({ sessionId, hostEmail, guestEmail: email, cfg });
}

exports.handleIncomingInviteIfBot = handleIncomingInviteIfBot;

exports.tickBots = onSchedule(
  {
    schedule: "every 5 minutes",
    timeZone: "Asia/Kolkata",
    region: REGION,
    timeoutSeconds: 180,
    memory: "512MiB",
  },
  async () => {
    const result = await runBotTick();
    console.log("tickBots", result);
    return result;
  },
);

exports.onBotBattleMatchWritten = onDocumentWritten(
  {
    document: "battle_matches/{sessionId}",
    region: REGION,
    timeoutSeconds: 540,
    memory: "256MiB",
  },
  async (event) => {
    const afterSnap = event.data && event.data.after;
    if (!afterSnap || !afterSnap.exists) return null;
    const sessionId = event.params.sessionId;
    try {
      return await onBattleMatchWritten(sessionId, afterSnap.data() || {});
    } catch (e) {
      console.error("onBotBattleMatchWritten", sessionId, e);
      return null;
    }
  },
);

exports.onBotBattlePaperSubmitted = onDocumentWritten(
  {
    document: "battle_matches/{sessionId}/joined_users/{participantId}",
    region: REGION,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async (event) => {
    const afterSnap = event.data && event.data.after;
    if (!afterSnap || !afterSnap.exists) return null;
    const after = afterSnap.data() || {};
    if (after.battle_paper_submitted !== true) return null;
    const beforeSnap = event.data && event.data.before;
    const before = beforeSnap && beforeSnap.exists ? beforeSnap.data() || {} : {};
    if (before.battle_paper_submitted === true) return null;
    const sessionId = event.params.sessionId;
    const participantId = event.params.participantId;
    try {
      return await onBattlePaperSubmitted(sessionId, participantId);
    } catch (e) {
      console.error("onBotBattlePaperSubmitted", sessionId, participantId, e);
      return null;
    }
  },
);

exports.adminRunBotTick = onCall({ region: REGION }, async (request) => {
  assertAdmin(request);
  return runBotTick();
});

exports.adminPlanBotDay = onCall({ region: REGION }, async (request) => {
  assertAdmin(request);
  const cfg = await readBotConfig();
  return planToday(cfg);
});
