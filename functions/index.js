const functions = require("firebase-functions");
const { onDocumentWritten } = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const MAX_BODY_LEN = 180;

/**
 * Instagram OAuth (Meta) — configured via:
 *   firebase functions:config:set instagram.app_id="..." instagram.app_secret="..."
 * Optional override (must match the app + Meta dashboard):
 *   instagram.redirect_uri="upscwars://instagram-callback"
 */
function instagramConfig() {
  const cfg = functions.config().instagram || {};
  return {
    appId: (cfg.app_id || "").toString().trim(),
    appSecret: (cfg.app_secret || "").toString().trim(),
    redirectUri: (cfg.redirect_uri || "upscwars://instagram-callback").toString().trim(),
  };
}

/**
 * Exchanges an authorization code, fetches @username from Graph API, writes
 * `insta`, `insta_user_id`, `insta_linked_at` on `users/{email}` (admin SDK).
 */
exports.completeInstagramLink = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "Sign in required to link Instagram.",
    );
  }
  const tokenEmail = context.auth.token.email;
  if (!tokenEmail || typeof tokenEmail !== "string") {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Your account must have an email to link Instagram.",
    );
  }
  const email = tokenEmail.toLowerCase().trim();

  const codeRaw = data && data.code;
  if (typeof codeRaw !== "string" || !codeRaw.trim()) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Authorization code is required.",
    );
  }
  let code = codeRaw.trim();
  if (code.includes("#_")) {
    code = code.split("#_")[0];
  }

  const { appId, appSecret, redirectUri } = instagramConfig();
  if (!appId || !appSecret) {
    functions.logger.error("completeInstagramLink: missing instagram config");
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Instagram linking is not configured on the server.",
    );
  }

  const params = new URLSearchParams();
  params.append("client_id", appId);
  params.append("client_secret", appSecret);
  params.append("grant_type", "authorization_code");
  params.append("redirect_uri", redirectUri);
  params.append("code", code);

  let tokenJson;
  try {
    const tokenRes = await fetch("https://api.instagram.com/oauth/access_token", {
      method: "POST",
      headers: { "Content-Type": "application/x-www-form-urlencoded" },
      body: params.toString(),
    });
    const text = await tokenRes.text();
    try {
      tokenJson = JSON.parse(text);
    } catch (e) {
      functions.logger.error("completeInstagramLink: token response not JSON", {
        status: tokenRes.status,
        body: text.slice(0, 500),
      });
      throw new functions.https.HttpsError(
        "internal",
        "Instagram token exchange failed.",
      );
    }
    if (!tokenRes.ok || !tokenJson.access_token) {
      functions.logger.warn("completeInstagramLink: token error", {
        status: tokenRes.status,
        body: tokenJson,
      });
      throw new functions.https.HttpsError(
        "permission-denied",
        (tokenJson.error_message || tokenJson.error || "Could not link Instagram. Try again."),
      );
    }
  } catch (e) {
    if (e instanceof functions.https.HttpsError) throw e;
    functions.logger.error("completeInstagramLink: fetch failed", {
      error: e && e.message ? e.message : String(e),
    });
    throw new functions.https.HttpsError(
      "internal",
      "Could not reach Instagram. Check your connection.",
    );
  }

  const accessToken = tokenJson.access_token;
  const userIdFromToken =
    tokenJson.user_id != null ? String(tokenJson.user_id) : null;

  const meUrl =
    "https://graph.instagram.com/v21.0/me?fields=user_id,username&access_token=" +
    encodeURIComponent(accessToken);
  let meJson;
  try {
    const meRes = await fetch(meUrl);
    const meText = await meRes.text();
    meJson = JSON.parse(meText);
    if (!meRes.ok || !meJson.username) {
      functions.logger.warn("completeInstagramLink: /me failed", {
        status: meRes.status,
        body: meJson,
      });
      throw new functions.https.HttpsError(
        "internal",
        "Could not read your Instagram profile.",
      );
    }
  } catch (e) {
    if (e instanceof functions.https.HttpsError) throw e;
    functions.logger.error("completeInstagramLink: /me error", {
      error: e && e.message ? e.message : String(e),
    });
    throw new functions.https.HttpsError(
      "internal",
      "Could not read your Instagram profile.",
    );
  }

  const igUserId = String(
    meJson.user_id != null
      ? meJson.user_id
      : meJson.id != null
        ? meJson.id
        : userIdFromToken || "",
  );
  if (!igUserId) {
    throw new functions.https.HttpsError(
      "internal",
      "Instagram did not return a user id.",
    );
  }

  const username = String(meJson.username).replace(/^@/, "").trim();
  if (!username) {
    throw new functions.https.HttpsError(
      "internal",
      "Instagram did not return a username.",
    );
  }

  const db = admin.firestore();
  const dup = await db
    .collection("users")
    .where("insta_user_id", "==", igUserId)
    .limit(2)
    .get();

  const other = dup.docs.find((d) => d.id !== email);
  if (other) {
    throw new functions.https.HttpsError(
      "already-exists",
      "This Instagram account is already linked to another profile.",
    );
  }

  const now = admin.firestore.FieldValue.serverTimestamp();
  await db.collection("users").doc(email).set(
    {
      insta: username,
      insta_user_id: igUserId,
      insta_linked_at: now,
      lastOnlineTime: Date.now(),
    },
    { merge: true },
  );

  functions.logger.info("completeInstagramLink: success", { email, igUserId });
  return { ok: true, username };
});

/**
 * Clears Instagram link fields (admin SDK). Callable only.
 */
exports.unlinkInstagram = functions.https.onCall(async (data, context) => {
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
      "Your account must have an email.",
    );
  }
  const email = tokenEmail.toLowerCase().trim();
  await admin
    .firestore()
    .collection("users")
    .doc(email)
    .set(
      {
        insta: admin.firestore.FieldValue.delete(),
        insta_user_id: admin.firestore.FieldValue.delete(),
        insta_linked_at: admin.firestore.FieldValue.delete(),
        lastOnlineTime: Date.now(),
      },
      { merge: true },
    );
  functions.logger.info("unlinkInstagram", { email });
  return { ok: true };
});

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
