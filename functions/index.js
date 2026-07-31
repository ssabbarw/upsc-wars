const functions = require("firebase-functions");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

const MAX_BODY_LEN = 180;

/** FCM topic — must match Flutter [PushSpotTestConstants.broadcastFcmTopic]. */
const SPOT_TEST_BROADCAST_TOPIC = "upsc_wars_spot_tests";

function spotTestBroadcastAllowlist() {
  const raw = process.env.SPOT_TEST_BROADCAST_EMAILS || "";
  return new Set(
    raw
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  );
}

function questionEditorAllowlist() {
  const raw = process.env.QUESTION_EDITOR_EMAILS || "";
  return new Set(
    raw
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  );
}

const QUESTION_CORRECTIONS_ACTIVE_PATH = "question_corrections/active";
const MAX_CORRECTIONS_PER_ACTIVE_DOC = 400;

function buildSpotTestFcmData(data) {
  const notificationId = crypto.randomUUID();
  const fcmData = {
    kind: "push_spot_test",
    notification_id: notificationId,
  };
  const subjectRaw = data && data.subject;
  const topicRaw = data && data.topic;
  const subtopicRaw = data && data.subtopic;
  const questionUuidRaw = data && data.question_uuid;

  if (typeof subjectRaw === "string" && subjectRaw.trim()) {
    fcmData.subject = subjectRaw.trim();
  }
  if (typeof topicRaw === "string" && topicRaw.trim()) {
    fcmData.topic = topicRaw.trim();
  }
  if (typeof subtopicRaw === "string" && subtopicRaw.trim()) {
    fcmData.subtopic = subtopicRaw.trim();
  }
  if (typeof questionUuidRaw === "string" && questionUuidRaw.trim()) {
    fcmData.question_uuid = questionUuidRaw.trim();
  }
  return { fcmData, notificationId };
}

/**
 * HTTPS callable `sendBattleInvite` — invoked from Flutter
 * `BattleInviteCloudService` with:
 *   guestEmail, sessionId, hostDisplayName, subjectLabel
 */
/**
 * HTTPS callable `publishQuestionCorrection` — merges one canonical correction
 * map into `question_corrections/active` (keyed by uuid).
 *
 * Env: QUESTION_EDITOR_EMAILS (comma-separated allowlist).
 */
exports.publishQuestionCorrection = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Sign in required to publish corrections.",
      );
    }

    const tokenEmail = context.auth.token.email;
    if (!tokenEmail || typeof tokenEmail !== "string") {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Your account must have an email to publish corrections.",
      );
    }

    const callerEmail = tokenEmail.toLowerCase().trim();
    const allowlist = questionEditorAllowlist();
    if (!allowlist.has(callerEmail)) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "Your account is not allowed to publish corrections.",
      );
    }

    const correction = data && data.correction;
    if (!correction || typeof correction !== "object") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "correction object is required.",
      );
    }

    const uuid =
      typeof correction.uuid === "string" ? correction.uuid.trim() : "";
    if (!uuid) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "correction.uuid is required.",
      );
    }

    const db = admin.firestore();
    const ref = db.doc(QUESTION_CORRECTIONS_ACTIVE_PATH);
    const now = admin.firestore.FieldValue.serverTimestamp();

    const revision = await db.runTransaction(async (tx) => {
      const snap = await tx.get(ref);
      const current = snap.exists ? snap.data() || {} : {};
      const prevCorrections =
        current.corrections && typeof current.corrections === "object"
          ? current.corrections
          : {};
      const keys = Object.keys(prevCorrections);
      if (keys.length >= MAX_CORRECTIONS_PER_ACTIVE_DOC && !prevCorrections[uuid]) {
        throw new functions.https.HttpsError(
          "resource-exhausted",
          "Active corrections doc is full; archive required.",
        );
      }

      const nextRevision = (current.revision || 0) + 1;
      const nextCorrections = { ...prevCorrections, [uuid]: correction };
      tx.set(ref, {
        revision: nextRevision,
        updated_at: now,
        updated_by: callerEmail,
        corrections: nextCorrections,
      });
      return nextRevision;
    });

    functions.logger.info("publishQuestionCorrection: ok", {
      uuid,
      revision,
      editor: callerEmail,
    });

    return { revision, uuid };
  },
);

exports.sendBattleInvite = functions.https.onCall(async (data, context) => {
  functions.logger.info("sendBattleInvite: invoked", {
    uid: context.auth && context.auth.uid,
    hasAuth: Boolean(context.auth),
  });

  if (!context.auth) {
    functions.logger.warn("sendBattleInvite: rejected unauthenticated");
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign in required to send a battle invite.",
    );
  }

  const tokenEmail = context.auth.token.email;
  if (!tokenEmail || typeof tokenEmail !== "string") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Your account must have an email to send invites.",
    );
  }

  const callerEmail = tokenEmail.toLowerCase().trim();
  const guestEmailRaw = data && data.guestEmail;
  const sessionIdRaw = data && data.sessionId;
  const hostDisplayNameRaw = data && data.hostDisplayName;
  const subjectLabelRaw = data && data.subjectLabel;

  if (typeof guestEmailRaw !== "string" || !guestEmailRaw.trim()) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "guestEmail is required.",
    );
  }
  if (typeof sessionIdRaw !== "string" || !sessionIdRaw.trim()) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "sessionId is required.",
    );
  }

  const guestEmail = guestEmailRaw.toLowerCase().trim();
  const sessionId = sessionIdRaw.trim();

  functions.logger.info("sendBattleInvite: payload", {
    sessionId,
    guestEmail,
    callerEmail,
  });

  const hostDisplayName =
    typeof hostDisplayNameRaw === "string" && hostDisplayNameRaw.trim()
      ? hostDisplayNameRaw.trim()
      : "Someone";
  const subjectLabel =
    typeof subjectLabelRaw === "string" && subjectLabelRaw.trim()
      ? subjectLabelRaw.trim()
      : "Battle";

  const matchRef = admin.firestore().collection("battle_matches").doc(sessionId);
  const matchSnap = await matchRef.get();
  if (!matchSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Battle session was not found.",
    );
  }

  const match = matchSnap.data() || {};
  const hostEmail = (match.host_email || "").toString().toLowerCase();
  const matchGuest = (match.guest_email || "").toString().toLowerCase();
  const battleMode = (match.battle_mode || "").toString();

  if (battleMode !== "human") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Invites are only supported for human battles.",
    );
  }
  if (hostEmail !== callerEmail) {
    throw new functions.https.HttpsError(
      "permission-denied",
      "Only the battle host can send this invite.",
    );
  }
  if (matchGuest !== guestEmail) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "guestEmail does not match this battle.",
    );
  }

  const db = admin.firestore();
  const hostBlockedGuestRef = db
    .collection("users")
    .doc(hostEmail)
    .collection("blocked")
    .doc(guestEmail);
  const guestBlockedHostRef = db
    .collection("users")
    .doc(guestEmail)
    .collection("blocked")
    .doc(hostEmail);
  const [hostBlockedSnap, guestBlockedSnap] = await Promise.all([
    hostBlockedGuestRef.get(),
    guestBlockedHostRef.get(),
  ]);
  if (hostBlockedSnap.exists || guestBlockedSnap.exists) {
    functions.logger.info("sendBattleInvite: blocked relation", {
      sessionId,
      guestEmail,
      hostEmail,
    });
    return { ok: false, reason: "blocked" };
  }

  functions.logger.info("sendBattleInvite: match checks passed", {
    sessionId,
    guestEmail,
    battleMode,
  });

  const userSnap = await db.collection("users").doc(guestEmail).get();
  const userData = userSnap.data() || {};
  const fcmToken = userData.fcm_token || userData.fcmToken;
  if (!fcmToken || typeof fcmToken !== "string") {
    functions.logger.warn("sendBattleInvite: no FCM token on users doc", {
      guestEmail,
      sessionId,
    });
    return { ok: false, reason: "no_token" };
  }

  functions.logger.info("sendBattleInvite: sending FCM", {
    sessionId,
    guestEmail,
    tokenPrefix: fcmToken.slice(0, 8),
  });

  const bodyBase = `${hostDisplayName} challenged you (${subjectLabel})`;
  const body =
    bodyBase.length > MAX_BODY_LEN
      ? `${bodyBase.slice(0, MAX_BODY_LEN - 1)}…`
      : bodyBase;

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Battle invite",
        body,
      },
      data: {
        sessionId: String(sessionId),
        notification_id: `battle__${String(sessionId)}`,
        kind: "battle_join",
      },
    });
  } catch (e) {
    functions.logger.error("sendBattleInvite: FCM send failed", {
      guestEmail,
      sessionId,
      error: e && e.message ? e.message : String(e),
    });
    return { ok: false, reason: "send_failed" };
  }

  functions.logger.info("sendBattleInvite: FCM delivered", {
    sessionId,
    guestEmail,
  });

  return { ok: true };
});

/**
 * HTTPS callable `sendSelfTestNotification` — sends one FCM to the caller’s
 * own device (reads `users/{callerEmail}.fcm_token`). For one-device testing.
 */
exports.sendSelfTestNotification = functions.https.onCall(async (data, context) => {
  functions.logger.info("sendSelfTestNotification: invoked", {
    uid: context.auth && context.auth.uid,
  });

  if (!context.auth) {
    functions.logger.warn("sendSelfTestNotification: unauthenticated");
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign in required.",
    );
  }

  const tokenEmail = context.auth.token.email;
  if (!tokenEmail || typeof tokenEmail !== "string") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Your account must have an email for this test.",
    );
  }

  const email = tokenEmail.toLowerCase().trim();
  functions.logger.info("sendSelfTestNotification: loading token", { email });

  const userSnap = await admin.firestore().collection("users").doc(email).get();
  const userData = userSnap.data() || {};
  const fcmToken = userData.fcm_token || userData.fcmToken;
  if (!fcmToken || typeof fcmToken !== "string") {
    functions.logger.warn("sendSelfTestNotification: no token", { email });
    return { ok: false, reason: "no_token" };
  }

  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: "Upsc Wars",
        body: "Success — push notifications are working.",
      },
      data: {
        kind: "self_test",
      },
    });
  } catch (e) {
    functions.logger.error("sendSelfTestNotification: FCM failed", {
      email,
      error: e && e.message ? e.message : String(e),
    });
    return { ok: false, reason: "send_failed" };
  }

  functions.logger.info("sendSelfTestNotification: delivered", { email });
  return { ok: true };
});

/**
 * HTTPS callable `sendSpotTestNotification` — spot-test FCM to the caller's
 * device (`target: self`) or all subscribers on [SPOT_TEST_BROADCAST_TOPIC]
 * (`target: broadcast`, allowlisted emails only).
 */
exports.sendSpotTestNotification = functions.https.onCall(async (data, context) => {
  functions.logger.info("sendSpotTestNotification: invoked", {
    uid: context.auth && context.auth.uid,
    target: data && data.target,
  });

  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign in required.",
    );
  }

  const tokenEmail = context.auth.token.email;
  if (!tokenEmail || typeof tokenEmail !== "string") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Your account must have an email for this test.",
    );
  }

  const titleRaw = data && data.title;
  const bodyRaw = data && data.body;
  const title =
    typeof titleRaw === "string" && titleRaw.trim()
      ? titleRaw.trim().slice(0, 120)
      : "";
  const body =
    typeof bodyRaw === "string" && bodyRaw.trim()
      ? bodyRaw.trim().slice(0, MAX_BODY_LEN)
      : "";

  if (!title || !body) {
    return { ok: false, reason: "invalid_argument" };
  }

  const email = tokenEmail.toLowerCase().trim();
  const targetRaw = data && data.target;
  const target =
    typeof targetRaw === "string" && targetRaw.trim() === "broadcast"
      ? "broadcast"
      : "self";
  const { fcmData, notificationId } = buildSpotTestFcmData(data);
  const message = {
    notification: { title, body },
    data: fcmData,
  };

  const notifRef = admin
    .firestore()
    .collection("admin_dashboard")
    .doc("notifications")
    .collection("items")
    .doc(notificationId);
  await notifRef.set(
    {
      kind: "push_spot_test",
      title,
      sent_at: admin.firestore.FieldValue.serverTimestamp(),
      opens: 0,
      conversions: 0,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  if (target === "broadcast") {
    const allowlist = spotTestBroadcastAllowlist();
    if (!allowlist.has(email)) {
      functions.logger.warn("sendSpotTestNotification: broadcast denied", {
        email,
      });
      return { ok: false, reason: "not_authorized" };
    }
    try {
      await admin.messaging().send({
        ...message,
        topic: SPOT_TEST_BROADCAST_TOPIC,
      });
    } catch (e) {
      functions.logger.error("sendSpotTestNotification: broadcast failed", {
        email,
        error: e && e.message ? e.message : String(e),
      });
      return { ok: false, reason: "send_failed" };
    }
    functions.logger.info("sendSpotTestNotification: broadcast delivered", {
      email,
      topic: SPOT_TEST_BROADCAST_TOPIC,
    });
    return { ok: true, target: "broadcast", notificationId };
  }

  const userSnap = await admin.firestore().collection("users").doc(email).get();
  const userData = userSnap.data() || {};
  const fcmToken = userData.fcm_token || userData.fcmToken;
  if (!fcmToken || typeof fcmToken !== "string") {
    functions.logger.warn("sendSpotTestNotification: no token", { email });
    return { ok: false, reason: "no_token" };
  }

  try {
    await admin.messaging().send({
      ...message,
      token: fcmToken,
    });
  } catch (e) {
    functions.logger.error("sendSpotTestNotification: FCM failed", {
      email,
      error: e && e.message ? e.message : String(e),
    });
    return { ok: false, reason: "send_failed" };
  }

  functions.logger.info("sendSpotTestNotification: delivered", { email });
  return { ok: true, target: "self", notificationId };
});

/**
 * RTDB trigger: notify peer on new chat message.
 */
exports.onChatMessageCreated = functions.database
  .ref("/chatMessages/{chatId}/{messageId}")
  .onCreate(async (snapshot, context) => {
    const value = snapshot.val() || {};
    const senderEmail = (value.senderEmail || "").toString().toLowerCase().trim();
    const text = (value.text || "").toString().trim();
    if (!senderEmail || !text) return null;

    const threadSnap = await admin
      .database()
      .ref(`/chatThreads/${context.params.chatId}/participantEmails`)
      .once("value");
    const participants = threadSnap.val();
    if (!Array.isArray(participants) || participants.length < 2) {
      return null;
    }
    const recipientEmail = participants
      .map((item) => (item || "").toString().toLowerCase().trim())
      .find((email) => email && email !== senderEmail);
    if (!recipientEmail) return null;

    const recipientBlockedSenderSnap = await admin
      .firestore()
      .collection("users")
      .doc(recipientEmail)
      .collection("blocked")
      .doc(senderEmail)
      .get();
    if (recipientBlockedSenderSnap.exists) {
      functions.logger.info("onChatMessageCreated: skip FCM, recipient blocked sender", {
        chatId: context.params.chatId,
        recipientEmail,
        senderEmail,
      });
      return null;
    }

    const userSnap = await admin.firestore().collection("users").doc(recipientEmail).get();
    const userData = userSnap.data() || {};
    const fcmToken = userData.fcm_token || userData.fcmToken;
    if (!fcmToken || typeof fcmToken !== "string") {
      return null;
    }

    const senderSnap = await admin.firestore().collection("users").doc(senderEmail).get();
    const senderName = ((senderSnap.data() || {}).name || senderEmail).toString();
    const body = text.length > MAX_BODY_LEN ? `${text.slice(0, MAX_BODY_LEN - 1)}…` : text;

    try {
      await admin.messaging().send({
        token: fcmToken,
        notification: {
          title: senderName,
          body,
        },
        data: {
          kind: "chat_message",
          chatId: String(context.params.chatId),
          senderEmail,
        },
      });
    } catch (e) {
      functions.logger.error("onChatMessageCreated: FCM send failed", {
        chatId: context.params.chatId,
        recipientEmail,
        error: e && e.message ? e.message : String(e),
      });
    }

    return null;
  });

const OPEN_CHALLENGE_RESERVED = new Set(["questions", "subject", "created_at", "expires_at"]);

function openChallengeDocIsExpired(data) {
  const exp = data.expires_at;
  const cr = data.created_at;
  let endMs = null;
  if (exp && typeof exp.toMillis === "function") {
    endMs = exp.toMillis();
  } else if (cr && typeof cr.toMillis === "function") {
    endMs = cr.toMillis() + 24 * 60 * 60 * 1000;
  }
  if (endMs == null) return false;
  return Date.now() > endMs;
}

function openChallengeReadAttempts(data) {
  const out = {};
  if (!data) return out;
  for (const key of Object.keys(data)) {
    if (OPEN_CHALLENGE_RESERVED.has(key)) continue;
    const v = data[key];
    if (!v || typeof v !== "object") continue;
    const score = Number(v.score);
    if (!Number.isFinite(score)) continue;
    const profile = v.profile && typeof v.profile === "object" ? v.profile : {};
    const name = (profile.name || key).toString().trim() || "Someone";
    const emailKey = key.toLowerCase().trim();
    out[emailKey] = { score, name };
  }
  return out;
}

async function sendOpenChallengePush(db, recipientEmail, title, body, challengeId) {
  const userSnap = await db.collection("users").doc(recipientEmail).get();
  const userData = userSnap.data() || {};
  const fcmToken = userData.fcm_token || userData.fcmToken;
  if (!fcmToken || typeof fcmToken !== "string") {
    functions.logger.warn("onOpenChallengeWritten: no FCM token", { recipientEmail });
    return;
  }
  const safeBody =
    body.length > MAX_BODY_LEN ? `${body.slice(0, MAX_BODY_LEN - 1)}…` : body;
  const safeTitle =
    title.length > 60 ? `${title.slice(0, 59)}…` : title;
  try {
    await admin.messaging().send({
      token: fcmToken,
      notification: {
        title: safeTitle,
        body: safeBody,
      },
      data: {
        kind: "open_challenge",
        challengeId: String(challengeId),
      },
    });
    functions.logger.info("onOpenChallengeWritten: FCM sent", {
      recipientEmail,
      challengeId,
    });
  } catch (e) {
    functions.logger.error("onOpenChallengeWritten: FCM failed", {
      recipientEmail,
      challengeId,
      error: e && e.message ? e.message : String(e),
    });
  }
}

/**
 * After a new attempt is merged into `open_challenges/{id}`, notify every user
 * who had already attempted (creator or not) with outcome vs the newcomer.
 */
exports.onOpenChallengeWritten = onDocumentWritten(
  "open_challenges/{challengeId}",
  async (event) => {
    const challengeId = event.params.challengeId;
    const afterSnap = event.data.after;
    if (!afterSnap.exists) {
      return null;
    }
    const beforeSnap = event.data.before;
    if (!beforeSnap.exists) {
      functions.logger.info("onOpenChallengeWritten: create, skip fanout", {
        challengeId,
      });
      return null;
    }

    const before = beforeSnap.data() || {};
    const after = afterSnap.data() || {};
    if (openChallengeDocIsExpired(after)) {
      functions.logger.info("onOpenChallengeWritten: expired doc, skip fanout", {
        challengeId,
      });
      return null;
    }
    const beforeAttempts = openChallengeReadAttempts(before);
    const afterAttempts = openChallengeReadAttempts(after);
    const newKeys = Object.keys(afterAttempts).filter((k) => !beforeAttempts[k]);
    if (newKeys.length !== 1) {
      functions.logger.warn(
        "onOpenChallengeWritten: expected exactly one new participant",
        { challengeId, newKeyCount: newKeys.length },
      );
      return null;
    }

    const newEmail = newKeys[0];
    const newcomer = afterAttempts[newEmail];
    if (!newcomer) return null;

    const subjectLabel =
      (after.subject || "Challenge").toString().trim() || "Challenge";
    const yScore = newcomer.score;
    const newcomerName = newcomer.name;

    const db = admin.firestore();
    const tasks = [];

    for (const email of Object.keys(beforeAttempts)) {
      if (email === newEmail) continue;
      const peer = beforeAttempts[email];
      if (!peer) continue;
      const xScore = peer.score;
      let body;
      if (yScore > xScore) {
        body =
          `Your score was beaten — ${newcomerName} scored ${yScore}/10 on “${subjectLabel}”. Tap to view.`;
      } else if (yScore < xScore) {
        body =
          `${newcomerName} attempted “${subjectLabel}” but didn’t beat your score (${xScore}/10 vs ${yScore}/10).`;
      } else {
        body =
          `Tie: ${newcomerName} matched your score (${yScore}/10) on “${subjectLabel}”. You stay ahead with an earlier attempt.`;
      }
      tasks.push(
        sendOpenChallengePush(
          db,
          email,
          "Open challenge",
          body,
          challengeId,
        ),
      );
    }

    await Promise.all(tasks);
    return null;
  },
);

// --- Daily War (scheduled + callable) ---
const dailyWar = require("./daily_war");
exports.generateDailyWar = dailyWar.generateDailyWar;
exports.publishDailyWarQuestions = dailyWar.publishDailyWarQuestions;
exports.rankDailyWar = dailyWar.rankDailyWar;
exports.submitDailyWar = dailyWar.submitDailyWar;
exports.adminGenerateDailyWar = dailyWar.adminGenerateDailyWar;
