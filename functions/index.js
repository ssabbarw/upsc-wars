const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

const MAX_BODY_LEN = 180;

/**
 * HTTPS callable `sendBattleInvite` — invoked from Flutter
 * `BattleInviteCloudService` with:
 *   guestEmail, sessionId, hostDisplayName, subjectLabel
 */
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

  functions.logger.info("sendBattleInvite: match checks passed", {
    sessionId,
    guestEmail,
    battleMode,
  });

  const userSnap = await admin
    .firestore()
    .collection("users")
    .doc(guestEmail)
    .get();
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
