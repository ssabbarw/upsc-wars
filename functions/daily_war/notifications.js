/**
 * Daily War FCM — topic broadcasts + optional per-user AIR pushes.
 *
 * Topic: upsc_wars_daily_war (clients subscribe in FcmTokenSyncService).
 * data.kind = "daily_war" → app opens /daily-war
 */

const admin = require("firebase-admin");
const crypto = require("crypto");

const DAILY_WAR_FCM_TOPIC = "upsc_wars_daily_war";

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
  return kind === "grand" ? "Grand War" : "Daily War";
}

/**
 * @param {{ title: string, body: string, phase: string, dateId: string }} opts
 */
async function sendDailyWarTopic(opts) {
  const { title, body, phase, dateId } = opts;
  const notificationId = `daily_war_${phase}_${dateId}_${crypto.randomUUID().slice(0, 8)}`;
  await admin.messaging().send({
    topic: DAILY_WAR_FCM_TOPIC,
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
  return { ok: true, topic: DAILY_WAR_FCM_TOPIC, notificationId };
}

async function loadWarPublic(dateId) {
  const snap = await admin.firestore().collection("daily_wars").doc(dateId).get();
  if (!snap.exists) return null;
  return snap.data() || {};
}

/** N1 / N7 · ~6:10 AM — tonight's topics announced. */
async function notifyMorning(dateId) {
  const war = await loadWarPublic(dateId);
  if (!war) {
    console.warn("notifyMorning: no war for", dateId);
    return { ok: false, reason: "no_war" };
  }
  const kind = war.kind || "daily";
  const phrase = topicsPhrase(war.topics);
  const q = war.question_count || (kind === "grand" ? 25 : 15);
  const mins = kind === "grand" ? 30 : 20;
  const title =
    kind === "grand"
      ? "Grand War tonight, 9 PM"
      : "Tonight, 9 PM: Daily War";
  const body =
    kind === "grand"
      ? phrase
        ? `${q} questions revising this week's topics — ${phrase}. ${mins} min, one attempt.`
        : `${q} questions, ${mins} minutes, one attempt. 9:00 PM IST.`
      : phrase
        ? `${phrase}. ${q} Q, ${mins} min. Prep today.`
        : `${q} questions, ${mins} minutes. Prep today.`;

  const result = await sendDailyWarTopic({
    title,
    body,
    phase: "morning",
    dateId,
  });
  return { ...result, kind };
}

/** N2 · 8:30 PM — 30 minutes out. */
async function notifyReminder30(dateId) {
  const war = await loadWarPublic(dateId);
  if (!war) return { ok: false, reason: "no_war" };
  const phrase = topicsPhrase(war.topics);
  const title = "War in 30 minutes";
  const body = phrase
    ? `${phrase}. Lobby opens 8:45 · starts 9:00 PM IST.`
    : "Lobby opens 8:45 · starts 9:00 PM IST.";
  return sendDailyWarTopic({ title, body, phase: "reminder_30", dateId });
}

/** N3 · 8:50 PM — lobby open. */
async function notifyLobbyOpen(dateId) {
  const war = await loadWarPublic(dateId);
  if (!war) return { ok: false, reason: "no_war" };
  const phrase = topicsPhrase(war.topics);
  const title = "Lobby is open";
  const body = phrase
    ? `${phrase}. Doors close at 9:00 PM IST.`
    : "Daily War lobby is open. Doors close at 9:00 PM IST.";
  return sendDailyWarTopic({ title, body, phase: "lobby", dateId });
}

/**
 * N6 · after rank — topic broadcast + personalized AIR when token found.
 * @param {string} dateId
 * @param {Array<{ uid: string, air: number, score: number, percentile: number }>} rankedRows
 */
async function notifyResultsReady(dateId, rankedRows) {
  const war = await loadWarPublic(dateId);
  const n = Array.isArray(rankedRows) ? rankedRows.length : 0;
  const title = "All-India Ranks are ready";
  const body =
    n > 0
      ? `Tonight's War results are in · ${n.toLocaleString("en-IN")} aspirants. Tap to see your AIR.`
      : "Tonight's War results are in. Tap to review.";

  const topicResult = await sendDailyWarTopic({
    title,
    body,
    phase: "results",
    dateId,
  });

  let personalSent = 0;
  let personalSkipped = 0;
  if (!rankedRows || rankedRows.length === 0) {
    return { ...topicResult, personalSent, personalSkipped };
  }

  const messages = [];
  for (const row of rankedRows) {
    try {
      const user = await admin.auth().getUser(row.uid);
      const email = (user.email || "").toLowerCase().trim();
      if (!email) {
        personalSkipped++;
        continue;
      }
      const userSnap = await admin.firestore().collection("users").doc(email).get();
      const token =
        (userSnap.data() &&
          (userSnap.data().fcm_token || userSnap.data().fcmToken)) ||
        null;
      if (!token || typeof token !== "string") {
        personalSkipped++;
        continue;
      }
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
          notification_id: `daily_war_air_${dateId}_${row.uid}`,
        },
        android: { priority: "high" },
        apns: {
          payload: { aps: { sound: "default" } },
        },
      });
    } catch (e) {
      personalSkipped++;
      console.warn("notifyResultsReady: skip uid", row.uid, e.message || e);
    }
  }

  // FCM sendEach max 500
  for (let i = 0; i < messages.length; i += 500) {
    const chunk = messages.slice(i, i + 500);
    const res = await admin.messaging().sendEach(chunk);
    personalSent += res.successCount || 0;
  }

  return { ...topicResult, personalSent, personalSkipped, participants: n };
}

module.exports = {
  DAILY_WAR_FCM_TOPIC,
  topicsPhrase,
  warTitle,
  sendDailyWarTopic,
  notifyMorning,
  notifyReminder30,
  notifyLobbyOpen,
  notifyResultsReady,
};
