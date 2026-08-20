/**
 * Daily War FCM — topic broadcasts + optional per-user AIR pushes.
 *
 * Topics:
 *   upsc_wars_daily_war         — everyone rollout
 *   upsc_wars_daily_war_admins  — admins-only rollout
 *
 * data.kind = "daily_war" → app opens /daily-war
 */

const admin = require("firebase-admin");
const crypto = require("crypto");

const DAILY_WAR_FCM_TOPIC = "upsc_wars_daily_war";
const DAILY_WAR_ADMIN_FCM_TOPIC = "upsc_wars_daily_war_admins";

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

function isDailyWarAdminEmail(email) {
  if (!email) return false;
  return ADMIN_EMAILS.has(String(email).trim().toLowerCase());
}

/**
 * Reads Remote Config rollout.
 * @returns {Promise<{ enabled: boolean, adminsOnly: boolean }>}
 */
async function readDailyWarRollout() {
  try {
    const template = await admin.remoteConfig().getTemplate();
    const params = template.parameters || {};
    const enabledRaw = params.daily_war_enabled?.defaultValue?.value;
    const adminsRaw = params.daily_war_admins_only?.defaultValue?.value;
    // Default: feature on for admins only (safe preview).
    const enabled =
      enabledRaw === undefined || enabledRaw === null || enabledRaw === ""
        ? true
        : enabledRaw === true ||
        enabledRaw === "true" ||
        enabledRaw === "1";
    const adminsOnly =
      adminsRaw === undefined || adminsRaw === null || adminsRaw === ""
        ? true
        : adminsRaw === true ||
        adminsRaw === "true" ||
        adminsRaw === "1";
    return { enabled, adminsOnly };
  } catch (e) {
    console.warn("readDailyWarRollout failed; defaulting enabled+admins-only", e);
    return { enabled: true, adminsOnly: true };
  }
}

function topicForRollout(adminsOnly) {
  return adminsOnly ? DAILY_WAR_ADMIN_FCM_TOPIC : DAILY_WAR_FCM_TOPIC;
}

const SUBJECT_LABELS = {
  polity: "Polity",
  economy: "Economy",
  geography: "Geography",
  environment: "Environment",
  modern_history: "Modern History",
  ancient_history: "Ancient History",
  medieval_history: "Medieval History",
  art_and_culture: "Art and Culture",
};

function subjectLabel(slug) {
  const key = String(slug || "")
    .trim()
    .toLowerCase();
  return SUBJECT_LABELS[key] || slug || "UPSC";
}

function topicsPhrase(topics) {
  if (!Array.isArray(topics) || topics.length === 0) return "";
  const subjects = [
    ...new Set(topics.map((t) => subjectLabel(t.subject || t.subjectSlug))),
  ];
  const names = topics.map((t) => t.topic).filter(Boolean);
  const subjectPart = subjects.join(" + ");
  const topicPart = names.join(" + ");
  return topicPart ? `${subjectPart} — ${topicPart}` : subjectPart;
}

function warTitle(kind) {
  return kind === "grand" ? "Grand War" : "Daily Battle";
}

/**
 * @param {{ title: string, body: string, phase: string, dateId: string, topic?: string }} opts
 */
async function sendDailyWarTopic(opts) {
  const { title, body, phase, dateId, topic } = opts;
  const notificationId = `daily_war_${phase}_${dateId}_${crypto.randomUUID().slice(0, 8)}`;
  const targetTopic = topic || DAILY_WAR_FCM_TOPIC;
  await admin.messaging().send({
    topic: targetTopic,
    notification: { title, body },
    data: {
      kind: "daily_war",
      phase: String(phase),
      dateId: String(dateId),
      notification_id: notificationId,
    },
    android: { priority: "high" },
    apns: {
      payload: {
        aps: { sound: "default" },
      },
    },
  });
  return { ok: true, topic: targetTopic, notificationId };
}

async function loadWarPublic(dateId) {
  const snap = await admin.firestore().collection("daily_wars").doc(dateId).get();
  if (!snap.exists) return null;
  return snap.data() || {};
}

async function withRolloutGate(sendFn) {
  const rollout = await readDailyWarRollout();
  if (!rollout.enabled) {
    return { ok: false, reason: "rc_disabled", ...rollout };
  }
  const topic = topicForRollout(rollout.adminsOnly);
  const result = await sendFn(topic, rollout);
  return { ...result, ...rollout };
}

/** N1 / N7 · ~6:10 AM — tonight's topics announced. */
async function notifyMorning(dateId) {
  return withRolloutGate(async (topic) => {
    const war = await loadWarPublic(dateId);
    if (!war) {
      console.warn("notifyMorning: no war for", dateId);
      return { ok: false, reason: "no_war" };
    }
    const kind = war.kind || "daily";
    const phrase = topicsPhrase(war.topics);
    const q = war.question_count || (kind === "grand" ? 25 : 15);
    const mins = Math.min(
      120,
      Math.max(1, Math.ceil((q * 80) / 60)),
    );
    const title =
      kind === "grand"
        ? `${warTitle(kind)} tonight, 9 PM`
        : `Tonight, 9 PM: ${warTitle(kind)}`;
    const body =
      kind === "grand"
        ? phrase
          ? `${q} questions revising this week's topics — ${phrase}. ${mins} min, one attempt.`
          : `${q} questions, ${mins} minutes, one attempt. 9:00 PM IST.`
        : phrase
          ? `${phrase}. ${q} Q, ${mins} min. Prep today.`
          : `${q} questions, ${mins} minutes. Prep today.`;

    return sendDailyWarTopic({
      title,
      body,
      phase: "morning",
      dateId,
      topic,
    });
  });
}

/** N2 · 8:30 PM — 30 minutes out. */
async function notifyReminder30(dateId) {
  return withRolloutGate(async (topic) => {
    const war = await loadWarPublic(dateId);
    if (!war) return { ok: false, reason: "no_war" };
    const phrase = topicsPhrase(war.topics);
    const kind = war.kind || "daily";
    const title =
      kind === "grand" ? "Grand War in 30 minutes" : "Daily Battle in 30 minutes";
    const body = phrase
      ? `${phrase}. Lobby opens 8:59 · starts 9:00 PM IST.`
      : "Lobby opens 8:59 · starts 9:00 PM IST.";
    return sendDailyWarTopic({
      title,
      body,
      phase: "reminder_30",
      dateId,
      topic,
    });
  });
}

/** N3 · 8:59 PM — lobby and paper open; synchronized start at 9:00. */
async function notifyLobbyOpen(dateId) {
  return withRolloutGate(async (topic) => {
    const war = await loadWarPublic(dateId);
    if (!war) return { ok: false, reason: "no_war" };
    const phrase = topicsPhrase(war.topics);
    const title = "Lobby is open";
    const body = phrase
      ? `${phrase}. Starts at 9:00 PM IST.`
      : "Daily Battle lobby is open. Starts at 9:00 PM IST.";
    return sendDailyWarTopic({
      title,
      body,
      phase: "lobby",
      dateId,
      topic,
    });
  });
}

/**
 * N6 · after rank — topic broadcast + personalized AIR when token found.
 * @param {string} dateId
 * @param {Array<{ uid: string, air: number, score: number, percentile: number }>} rankedRows
 */
async function notifyResultsReady(dateId, rankedRows) {
  return withRolloutGate(async (topic, rollout) => {
    const n = Array.isArray(rankedRows) ? rankedRows.length : 0;
    const title = "All-India Ranks are ready";
    const body =
      n > 0
        ? `Tonight's results are in · ${n.toLocaleString("en-IN")} aspirants. Tap to see your AIR.`
        : "Tonight's results are in. Tap to review.";

    const topicResult = await sendDailyWarTopic({
      title,
      body,
      phase: "results",
      dateId,
      topic,
    });

    let personalSent = 0;
    let personalSkipped = 0;
    if (!rankedRows || rankedRows.length === 0) {
      return { ...topicResult, personalSent, personalSkipped };
    }

    // Batch Auth + Firestore lookups (was N× getUser + N× users/{email}.get).
    const byUid = new Map();
    for (const row of rankedRows) {
      if (row && row.uid) byUid.set(String(row.uid), row);
    }
    const uids = [...byUid.keys()];
    const emailByUid = new Map();
    for (let i = 0; i < uids.length; i += 100) {
      const chunk = uids.slice(i, i + 100);
      try {
        const res = await admin.auth().getUsers(chunk.map((uid) => ({ uid })));
        for (const u of res.users || []) {
          const email = (u.email || "").toLowerCase().trim();
          if (email) emailByUid.set(u.uid, email);
        }
      } catch (e) {
        console.warn("notifyResultsReady: getUsers chunk failed", e.message || e);
      }
    }

    const db = admin.firestore();
    const emailEntries = [...emailByUid.entries()];
    const tokenByUid = new Map();
    for (let i = 0; i < emailEntries.length; i += 100) {
      const chunk = emailEntries.slice(i, i + 100);
      const refs = chunk.map(([, email]) => db.collection("users").doc(email));
      try {
        const snaps = await db.getAll(...refs);
        for (let j = 0; j < snaps.length; j++) {
          const [uid, email] = chunk[j];
          if (rollout.adminsOnly && !isDailyWarAdminEmail(email)) continue;
          const data = snaps[j].exists ? snaps[j].data() : null;
          const token = (data && (data.fcm_token || data.fcmToken)) || null;
          if (!token || typeof token !== "string") continue;
          tokenByUid.set(uid, token);
        }
      } catch (e) {
        console.warn("notifyResultsReady: users getAll failed", e.message || e);
      }
    }

    const messages = [];
    for (const [uid, row] of byUid) {
      const token = tokenByUid.get(uid);
      if (!token) continue;
      const air = row.air;
      const score = row.score;
      const pct = row.percentile;
      messages.push({
        token,
        notification: {
          title: `Your All-India Rank is ${air}`,
          body:
            pct != null
              ? `AIR ${air} of ${n} · ${Number(score).toFixed(2)} · percentile ${pct}. Review before you sleep.`
              : `AIR ${air} of ${n} · score ${Number(score).toFixed(2)}. Review before you sleep.`,
        },
        data: {
          kind: "daily_war",
          phase: "results_personal",
          dateId: String(dateId),
          air: String(air),
          notification_id: `daily_war_air_${dateId}_${uid}`,
        },
        android: { priority: "high" },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      });
    }
    personalSkipped = Math.max(0, n - messages.length);

    for (let i = 0; i < messages.length; i += 500) {
      const chunk = messages.slice(i, i + 500);
      const res = await admin.messaging().sendEach(chunk);
      personalSent += res.successCount || 0;
    }

    return {
      ...topicResult,
      personalSent,
      personalSkipped,
      participants: n,
    };
  });
}

module.exports = {
  DAILY_WAR_FCM_TOPIC,
  DAILY_WAR_ADMIN_FCM_TOPIC,
  isDailyWarAdminEmail,
  readDailyWarRollout,
  topicsPhrase,
  warTitle,
  sendDailyWarTopic,
  notifyMorning,
  notifyReminder30,
  notifyLobbyOpen,
  notifyResultsReady,
};
