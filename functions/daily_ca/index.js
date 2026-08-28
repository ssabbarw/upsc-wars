/**
 * Daily CA admin flow — drafts, publish, auto-publish, notify, ranks.
 *
 * Firestore:
 *   daily_ca_drafts/{YYYY-MM-DD}
 *   daily_mcqs/{YYYY}/{MM}/{DD}
 *   daily_ca_days/{YYYY-MM-DD}                    — rank day (live | frozen)
 *   daily_ca_days/{dateId}/private/answers         — keys (Functions only)
 *   daily_ca_days/{dateId}/submissions/{uid}
 *   daily_ca_days/{dateId}/meta/leaderboard        — top 100 snapshot
 *   daily_ca_state/ranks                           — current ranked date_id
 */
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const tls = require("tls");

const llmAdmin = require("../llm_admin");
const { parseJsonFromText } = require("../parse_llm_json");
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;
const DRAFTS = "daily_ca_drafts";
const LIVE = "daily_mcqs";
const DAYS = "daily_ca_days";
const CA_STATE = "daily_ca_state";
const RANKS_STATE_DOC = "ranks";
const MAX_ELAPSED_MS = 2 * 60 * 60 * 1000;
const PUBLISH_MIN = 5;
const PUBLISH_MAX = 10;
const ADMIN_EMAIL = (
  process.env.ADMIN_NOTIFY_EMAIL || "sachinsabbarwal@gmail.com"
)
  .trim()
  .toLowerCase();

/** Must match Flutter [DailyCaConstants.broadcastFcmTopic]. */
const DAILY_CA_FCM_TOPIC = "upsc_wars_daily_ca";

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

const URL_NS = Buffer.from("6ba7b8119dad11d180b400c04fd430c8", "hex");

function db() {
  return admin.firestore();
}

function isAdminEmail(email) {
  return ADMIN_EMAILS.has(String(email || "").trim().toLowerCase());
}

function requireAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const email = (request.auth.token.email || "").trim().toLowerCase();
  if (!isAdminEmail(email)) {
    throw new HttpsError("permission-denied", "Admin only.");
  }
  return email;
}

function formatIsoDate(ist) {
  const y = ist.getUTCFullYear();
  const m = String(ist.getUTCMonth() + 1).padStart(2, "0");
  const d = String(ist.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function istParts(utcDate = new Date()) {
  const shifted = new Date(utcDate.getTime() + IST_OFFSET_MS);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
    hour: shifted.getUTCHours(),
    weekday: shifted.getUTCDay(),
    iso: formatIsoDate(shifted),
  };
}

function addDaysIso(iso, days) {
  const [y, m, d] = iso.split("-").map(Number);
  const dt = new Date(Date.UTC(y, m - 1, d + days));
  return `${dt.getUTCFullYear()}-${String(dt.getUTCMonth() + 1).padStart(2, "0")}-${String(dt.getUTCDate()).padStart(2, "0")}`;
}

function yesterdayIso(parts) {
  return addDaysIso(parts.iso, -1);
}

function isSundayIso(iso) {
  const [y, m, d] = iso.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, d)).getUTCDay() === 0;
}

/** True once the paper quiz is open (next morning 6:00 AM IST). */
function isLive(iso, parts = istParts()) {
  const opensIso = addDaysIso(iso, 1);
  return parts.iso > opensIso || (parts.iso === opensIso && parts.hour >= 6);
}

function liveDocRef(iso) {
  const [y, m, d] = iso.split("-");
  return db().collection(LIVE).doc(y).collection(m).doc(d);
}

function draftRef(iso) {
  return db().collection(DRAFTS).doc(iso);
}

function uuidV5(name) {
  const hash = crypto.createHash("sha1");
  hash.update(URL_NS);
  hash.update(name);
  const bytes = Buffer.from(hash.digest().subarray(0, 16));
  bytes[6] = (bytes[6] & 0x0f) | 0x50;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;
  const hex = bytes.toString("hex");
  return `${hex.slice(0, 8)}-${hex.slice(8, 12)}-${hex.slice(12, 16)}-${hex.slice(16, 20)}-${hex.slice(20, 32)}`;
}

function liveUuid(sourceDate, poolOrder) {
  return uuidV5(`upsc-wars|ca|${sourceDate}|${poolOrder}`);
}

function enFingerprint(q) {
  const en = q && q.en && typeof q.en === "object" ? q.en : {};
  return JSON.stringify({
    display_text: en.display_text || "",
    table_data: en.table_data || null,
    final_explanation: en.final_explanation || "",
    strong_distractor: en.strong_distractor || "",
    elimination_logic: en.elimination_logic || [],
    upsc_trap_explanation: en.upsc_trap_explanation || "",
    statement_analysis: en.statement_analysis || null,
  });
}

function loadTranslatePrompt() {
  const bundled = path.join(__dirname, "translate_system.txt");
  return fs.readFileSync(bundled, "utf8").trim();
}

async function translateEnList(enList) {
  const cfg = await llmAdmin.loadLlmConfig();
  const { text } = await llmAdmin.anthropicJson({
    system: loadTranslatePrompt(),
    userContent: JSON.stringify(enList),
    model: cfg.caModel,
    apiKey: cfg.caApiKey,
    maxTokens: 16000,
  });
  const parsed = parseJsonFromText(text);
  if (!Array.isArray(parsed) || parsed.length !== enList.length) {
    throw new Error(
      `Translation length mismatch: got ${Array.isArray(parsed) ? parsed.length : typeof parsed}, expected ${enList.length}`,
    );
  }
  return parsed;
}

async function attachHindi(questions) {
  return translateEnList(questions.map((q) => q.en || {}));
}

function errorText(e) {
  if (e == null) return "unknown error";
  if (typeof e === "string") return e;
  const lines = [];
  if (e.code) lines.push(`code: ${e.code}`);
  if (e.message) lines.push(e.message);
  if (e.details) lines.push(String(e.details));
  if (e.stack) lines.push(e.stack);
  return lines.join("\n") || String(e);
}

async function emailStep(kind, iso, ok, extra) {
  const subject = `${ok ? "SUCCESS" : "FAILED"} — ${kind} — ${iso}`;
  const body = [
    `Step: ${kind}`,
    `Date: ${iso}`,
    `Result: ${ok ? "SUCCESS" : "FAILED"}`,
    extra ? `\n${extra}` : "",
  ]
    .filter((line) => line !== "")
    .join("\n");
  await sendAdminEmail(subject, body);
}

function pickQuestionsForAuto(draft) {
  const questions = Array.isArray(draft.questions) ? draft.questions : [];
  const chosenIds = Array.isArray(draft.chosen_uuids) ? draft.chosen_uuids : [];
  const byId = new Map(
    questions.map((q) => [String(q.draft_id || q.uuid || ""), q]),
  );
  const chosen = chosenIds
    .map((id) => byId.get(String(id)))
    .filter(Boolean);
  if (chosen.length >= PUBLISH_MIN) {
    return chosen.slice(0, PUBLISH_MAX);
  }
  if (questions.length >= PUBLISH_MAX) return questions.slice(0, PUBLISH_MAX);
  if (questions.length >= PUBLISH_MIN) return questions;
  return [];
}

function toLiveQuestion(q, sourceDate, poolOrder) {
  const meta = { ...(q.meta || {}) };
  meta.pool_order = poolOrder;
  meta.source_date = sourceDate;
  meta.source_kind = "current_affairs";
  const uuid = liveUuid(sourceDate, poolOrder);
  return {
    uuid,
    meta,
    shared: q.shared || {},
    en: q.en || {},
    hi: q.hi || {},
  };
}

async function writeLive(iso, questions, extraMeta) {
  const [y, m, d] = iso.split("-");
  await liveDocRef(iso).set({
    metadata: {
      date: iso,
      current_affairs_month: `${y}-${m}`,
      question_count: questions.length,
      hindi_available: questions.every((q) => q.hi && Object.keys(q.hi).length),
      schema_version: 3,
      published_at: new Date().toISOString(),
      ...(extraMeta || {}),
    },
    questions,
  });
}

function liveQuestionCount(questions) {
  if (Array.isArray(questions)) return questions.length;
  if (questions && typeof questions === "object") {
    return Object.keys(questions).length;
  }
  return 0;
}

async function liveDocHasQuestions(iso) {
  const snap = await liveDocRef(iso).get();
  if (!snap.exists) return false;
  const data = snap.data() || {};
  return liveQuestionCount(data.questions) > 0;
}

async function sendAdminFcm({ title, body, dateIso, status }) {
  const snap = await db().collection("users").doc(ADMIN_EMAIL).get();
  const token =
    (snap.exists && (snap.data().fcm_token || snap.data().fcmToken)) || null;
  if (!token) {
    console.warn("sendAdminFcm: no token for", ADMIN_EMAIL);
    return { sent: false, reason: "no_token" };
  }
  const notificationId = crypto.randomUUID();
  await admin.messaging().send({
    token,
    notification: { title, body },
    data: {
      kind: "daily_ca_review",
      date: dateIso,
      status: status || "",
      notification_id: notificationId,
    },
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default", badge: 1 } } },
  });
  return { sent: true };
}

async function sendDailyCaPaperTopic({ title, body, dateIso }) {
  const notificationId = `daily_ca_${dateIso}_${crypto.randomUUID().slice(0, 8)}`;
  await admin.messaging().send({
    topic: DAILY_CA_FCM_TOPIC,
    notification: { title, body },
    data: {
      kind: "daily_ca",
      date: dateIso,
      notification_id: notificationId,
    },
    android: { priority: "high" },
    apns: { payload: { aps: { sound: "default" } } },
  });
  return { ok: true, topic: DAILY_CA_FCM_TOPIC, notificationId };
}

async function sendAdminEmail(subject, body) {
  const sender = process.env.GMAIL_SENDER;
  const pass = process.env.GMAIL_APP_PASSWORD;
  const to = process.env.GMAIL_RECIPIENT || ADMIN_EMAIL;
  if (!sender || !pass) {
    console.warn("sendAdminEmail: GMAIL_SENDER/APP_PASSWORD not set");
    return;
  }
  const payload =
    `From: ${sender}\r\n` +
    `To: ${to}\r\n` +
    `Subject: [UPSC Pipeline] ${subject}\r\n` +
    `Content-Type: text/plain; charset=utf-8\r\n\r\n` +
    body;
  await new Promise((resolve, reject) => {
    const socket = tls.connect(
      { host: "smtp.gmail.com", port: 465, servername: "smtp.gmail.com" },
      () => {
        let buf = "";
        const send = (line) => socket.write(line + "\r\n");
        const steps = [
          null,
          `AUTH LOGIN`,
          Buffer.from(sender).toString("base64"),
          Buffer.from(pass).toString("base64"),
          `MAIL FROM:<${sender}>`,
          `RCPT TO:<${to}>`,
          "DATA",
          payload + "\r\n.",
          "QUIT",
        ];
        let i = 0;
        socket.on("data", (chunk) => {
          buf += chunk.toString();
          if (!buf.includes("\n")) return;
          buf = "";
          i += 1;
          if (i >= steps.length) {
            socket.end();
            resolve();
            return;
          }
          if (steps[i]) send(steps[i]);
        });
      },
    );
    socket.setTimeout(20000, () => {
      socket.destroy();
      reject(new Error("SMTP timeout"));
    });
    socket.on("error", reject);
    socket.on("end", resolve);
  }).catch((e) => {
    console.warn("sendAdminEmail failed", e);
  });
}

async function publishSelected(iso, selected, { auto }) {
  const publishKind = auto ? "Auto-publish" : "Manual publish";
  try {
    if (selected.length < PUBLISH_MIN || selected.length > PUBLISH_MAX) {
      throw new HttpsError(
        "failed-precondition",
        `Need ${PUBLISH_MIN}–${PUBLISH_MAX} questions, got ${selected.length}.`,
      );
    }

    const draftSnap = await draftRef(iso).get();
    const prevHiByDraftId = new Map();
    if (draftSnap.exists) {
      for (const q of draftSnap.data().questions || []) {
        if (q && q.hi && Object.keys(q.hi).length) {
          prevHiByDraftId.set(String(q.draft_id || q.uuid || ""), {
            hi: q.hi,
            fp: q.en_fingerprint || enFingerprint(q),
          });
        }
      }
    }

    const needTranslate = [];
    const needIndex = [];
    selected.forEach((q, i) => {
      const id = String(q.draft_id || q.uuid || "");
      const fp = enFingerprint(q);
      const prev = prevHiByDraftId.get(id);
      if (prev && prev.fp === fp && prev.hi) {
        selected[i] = { ...q, hi: prev.hi, en_fingerprint: fp };
      } else {
        needTranslate.push(q);
        needIndex.push(i);
      }
    });

    const chosenIds = selected.map((q) => String(q.draft_id || q.uuid || ""));
    const englishLive = selected.map((q, i) => toLiveQuestion(q, iso, i + 1));
    await writeLive(iso, englishLive, {
      auto: !!auto,
      hindi_pending: needTranslate.length > 0,
    });
    await draftRef(iso).set(
      {
        status: "published",
        published_at: admin.firestore.FieldValue.serverTimestamp(),
        published_count: englishLive.length,
        auto_published: !!auto,
        hindi_available: needTranslate.length === 0,
        chosen_uuids: chosenIds,
      },
      { merge: true },
    );
    await emailStep(
      publishKind,
      iso,
      true,
      `${englishLive.length} English questions written to daily_mcqs/${iso.replace(/-/g, "/")}.`,
    );

    let hindiOk = needTranslate.length === 0;
    if (needTranslate.length) {
      try {
        const hindi = await attachHindi(needTranslate);
        needIndex.forEach((qi, j) => {
          selected[qi] = {
            ...selected[qi],
            hi: hindi[j] || {},
            en_fingerprint: enFingerprint(selected[qi]),
          };
        });
        const liveWithHi = selected.map((q, i) => toLiveQuestion(q, iso, i + 1));
        await writeLive(iso, liveWithHi, { auto: !!auto });
        hindiOk = true;
        await emailStep(
          "Hindi translation",
          iso,
          true,
          `${needTranslate.length} questions translated.`,
        );
      } catch (e) {
        console.error("Hindi translation failed; English paper is live", iso, e);
        await emailStep("Hindi translation", iso, false, errorText(e));
      }
    } else {
      await emailStep(
        "Hindi translation",
        iso,
        true,
        "Reused existing Hindi. No new translation call.",
      );
    }

    const liveQuestions = hindiOk
      ? selected.map((q, i) => toLiveQuestion(q, iso, i + 1))
      : englishLive;

    const mergedQuestions = (
      draftSnap.exists ? draftSnap.data().questions : selected
    ).map((q) => {
      const id = String(q.draft_id || q.uuid || "");
      const updated = selected.find(
        (s) => String(s.draft_id || s.uuid || "") === id,
      );
      return updated || q;
    });

    await draftRef(iso).set(
      {
        published_count: liveQuestions.length,
        hindi_available: hindiOk,
        questions: mergedQuestions,
        chosen_uuids: chosenIds,
      },
      { merge: true },
    );

    try {
      await syncRankDay(iso, liveQuestions);
    } catch (e) {
      console.warn("syncRankDay after publish failed", iso, e);
    }

    return { count: liveQuestions.length, hindi: hindiOk };
  } catch (e) {
    await emailStep(publishKind, iso, false, errorText(e));
    if (e && typeof e === "object") e.publishEmailed = true;
    throw e;
  }
}

const callableOpts = {
  region: "asia-south1",
  timeoutSeconds: 300,
  memory: "512MiB",
};

const gmailSecrets = ["GMAIL_SENDER", "GMAIL_APP_PASSWORD", "GMAIL_RECIPIENT"];

const publishOpts = {
  ...callableOpts,
  timeoutSeconds: 540,
  secrets: ["ANTHROPIC_API_KEY", ...gmailSecrets],
};

exports.updateDailyCaDraft = onCall(callableOpts, async (request) => {
  const email = requireAdmin(request);
  const iso = String((request.data && request.data.date) || "").trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
    throw new HttpsError("invalid-argument", "date must be YYYY-MM-DD.");
  }
  if (isLive(iso) && (await liveDocHasQuestions(iso))) {
    throw new HttpsError(
      "failed-precondition",
      "This paper is already live. Use question corrections after 6 AM.",
    );
  }
  const questions = request.data && request.data.questions;
  const chosen = request.data && request.data.chosen_uuids;
  if (!Array.isArray(questions)) {
    throw new HttpsError("invalid-argument", "questions array is required.");
  }
  const chosenIds = Array.isArray(chosen)
    ? chosen.map((id) => String(id)).slice(0, PUBLISH_MAX)
    : [];
  await draftRef(iso).set(
    {
      questions,
      chosen_uuids: chosenIds,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_by: email,
    },
    { merge: true },
  );
  return { ok: true, chosen: chosenIds.length };
});

exports.publishDailyCaDay = onCall(publishOpts, async (request) => {
  requireAdmin(request);
  const iso = String((request.data && request.data.date) || "").trim();
  try {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
      throw new HttpsError("invalid-argument", "date must be YYYY-MM-DD.");
    }

    if (
      isLive(iso) &&
      (await liveDocHasQuestions(iso)) &&
      request.data &&
      request.data.allow_after_open !== true
    ) {
      throw new HttpsError(
        "failed-precondition",
        "This paper is already live. Use question corrections after 6 AM.",
      );
    }

    const snap = await draftRef(iso).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", `No draft for ${iso}.`);
    }
    const draft = snap.data() || {};
    const questions = Array.isArray(draft.questions) ? draft.questions : [];
    let selected = questions.filter((q) => q && q.chosen === true);
    if (selected.length === 0 && Array.isArray(draft.chosen_uuids)) {
      const want = new Set(draft.chosen_uuids.map(String));
      selected = questions.filter((q) =>
        want.has(String(q.draft_id || q.uuid || "")),
      );
    }
    if (request.data && Array.isArray(request.data.chosen_uuids) && request.data.chosen_uuids.length) {
      const want = new Set(request.data.chosen_uuids.map(String));
      selected = questions.filter((q) =>
        want.has(String(q.draft_id || q.uuid || "")),
      );
    }

    const result = await publishSelected(iso, selected, { auto: false });
    return { ok: true, ...result };
  } catch (e) {
    if (!e || !e.publishEmailed) {
      await emailStep("Manual publish", iso || "unknown", false, errorText(e));
    }
    throw e;
  }
});

async function autoPublishForIso(iso) {
  if (isSundayIso(iso)) {
    return { skipped: true, reason: "sunday" };
  }
  const snap = await draftRef(iso).get();
  if (!snap.exists) {
    await emailStep(
      "Auto-publish",
      iso,
      false,
      "No draft in daily_ca_drafts. Generation did not write this date.",
    );
    return { skipped: true, reason: "no_draft" };
  }
  const draft = snap.data() || {};
  if (draft.status === "published") {
    return { skipped: true, reason: "already_published" };
  }
  const selected = pickQuestionsForAuto(draft);
  if (selected.length < PUBLISH_MIN) {
    await draftRef(iso).set(
      { status: "skipped", skip_reason: "fewer_than_5" },
      { merge: true },
    );
    await sendAdminFcm({
      title: `CA skipped — ${iso}`,
      body: `Only ${Array.isArray(draft.questions) ? draft.questions.length : 0} drafts. Day skipped.`,
      dateIso: iso,
      status: "skipped",
    });
    await emailStep(
      "Auto-publish",
      iso,
      false,
      `Fewer than ${PUBLISH_MIN} valid questions (got ${selected.length}).`,
    );
    return { skipped: true, reason: "fewer_than_5" };
  }
  try {
    const result = await publishSelected(iso, selected, { auto: true });
    await sendAdminFcm({
      title: `CA auto-published — ${iso}`,
      body: `${result.count} questions are live.`,
      dateIso: iso,
      status: "published",
    });
    return result;
  } catch (e) {
    console.error("autoPublishDailyCa failed", iso, e);
    await sendAdminFcm({
      title: `CA publish failed — ${iso}`,
      body: "Auto-publish failed. Check the pipeline email.",
      dateIso: iso,
      status: "failed",
    });
    throw e;
  }
}

exports.autoPublishDailyCa = onSchedule(
  {
    schedule: "0 0 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
    timeoutSeconds: 540,
    memory: "512MiB",
    secrets: ["ANTHROPIC_API_KEY", ...gmailSecrets],
  },
  async () => {
    const iso = yesterdayIso(istParts());
    try {
      const result = await autoPublishForIso(iso);
      console.log("autoPublishDailyCa", iso, result);
      return result;
    } catch (e) {
      console.error("autoPublishDailyCa", iso, e);
      return { iso, failed: true, error: errorText(e) };
    }
  },
);

/**
 * 7:00 AM IST — user-facing "paper quiz is live" to everyone on the topic.
 * Skips Monday (Sunday has no newspaper, so there is no fresh paper).
 */
exports.notifyDailyCaPaper = onSchedule(
  {
    schedule: "0 7 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
    timeoutSeconds: 60,
  },
  async () => {
    const parts = istParts();
    const contentIso = yesterdayIso(parts);
    if (isSundayIso(contentIso)) {
      console.log("notifyDailyCaPaper skipped: no fresh paper", contentIso);
      return { skipped: true, reason: "no_fresh_paper", date: contentIso };
    }
    if (!(await liveDocHasQuestions(contentIso))) {
      console.log("notifyDailyCaPaper skipped: no live paper", contentIso);
      return { skipped: true, reason: "no_live_paper", date: contentIso };
    }
    const snap = await liveDocRef(contentIso).get();
    const count = liveQuestionCount((snap.data() || {}).questions);
    const result = await sendDailyCaPaperTopic({
      title: "Today's paper quiz is live",
      body: `${count} MCQs from the news you just read`,
      dateIso: contentIso,
    });
    console.log("notifyDailyCaPaper sent", contentIso, result);
    return { ...result, date: contentIso, count };
  },
);

exports.adminAutoPublishDailyCa = onCall(publishOpts, async (request) => {
  requireAdmin(request);
  const iso =
    String((request.data && request.data.date) || "").trim() ||
    yesterdayIso(istParts());
  return autoPublishForIso(iso);
});

// --- Live rolling ranks -------------------------------------------------------

function ranksStateRef() {
  return db().collection(CA_STATE).doc(RANKS_STATE_DOC);
}

function dayRef(iso) {
  return db().collection(DAYS).doc(iso);
}

function coerceQuestionList(raw) {
  if (Array.isArray(raw)) return raw.filter((q) => q && typeof q === "object");
  if (raw && typeof raw === "object") {
    return Object.keys(raw)
      .sort((a, b) => Number(a) - Number(b))
      .map((k) => raw[k])
      .filter((q) => q && typeof q === "object");
  }
  return [];
}

function answersFromQuestions(questions) {
  const answers = {};
  const uuids = [];
  for (const q of questions || []) {
    const uuid = q && q.uuid ? String(q.uuid).trim() : "";
    if (!uuid) continue;
    uuids.push(uuid);
    const shared = q.shared && typeof q.shared === "object" ? q.shared : {};
    const key = String(shared.correct_option || "").trim().toLowerCase();
    if (key) answers[uuid] = key;
  }
  return { answers, uuids };
}

/** Matches Flutter DailyCaSchedule.paperQuizContentDate. */
function paperQuizContentIso(parts = istParts()) {
  let cursor = addDaysIso(parts.iso, -1);
  for (let i = 0; i < 9; i++) {
    if (!isSundayIso(cursor) && isLive(cursor, parts)) {
      return cursor;
    }
    cursor = addDaysIso(cursor, -1);
  }
  return null;
}

function parseRcBool(raw, fallback) {
  if (raw === undefined || raw === null || raw === "") return fallback;
  if (raw === true || raw === "true" || raw === "1") return true;
  if (raw === false || raw === "false" || raw === "0") return false;
  return fallback;
}

function flattenRcParams(template) {
  const out = { ...(template.parameters || {}) };
  const groups = template.parameterGroups || {};
  for (const group of Object.values(groups)) {
    Object.assign(out, (group && group.parameters) || {});
  }
  return out;
}

function rcParamValue(params, key) {
  const p = params[key];
  if (!p || !p.defaultValue) return undefined;
  if (p.defaultValue.useInAppDefault) return undefined;
  return p.defaultValue.value;
}

let _rolloutCache = { at: 0, value: null };
const ROLLOUT_TTL_MS = 10 * 60 * 1000;

async function readDailyCaRanksRollout() {
  if (_rolloutCache.value && Date.now() - _rolloutCache.at < ROLLOUT_TTL_MS) {
    return _rolloutCache.value;
  }
  try {
    const template = await admin.remoteConfig().getTemplate();
    const params = flattenRcParams(template);
    const enabledRaw = rcParamValue(params, "daily_ca_ranks_enabled");
    const adminsRaw = rcParamValue(params, "daily_ca_ranks_admins_only");
    const value = {
      enabled: parseRcBool(enabledRaw, true),
      adminsOnly: parseRcBool(adminsRaw, true),
    };
    _rolloutCache = { at: Date.now(), value };
    return value;
  } catch (e) {
    console.warn("readDailyCaRanksRollout failed; defaulting enabled+admins-only", e);
    const value = { enabled: true, adminsOnly: true };
    _rolloutCache = { at: Date.now(), value };
    return value;
  }
}

async function assertDailyCaRankParticipant(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const rollout = await readDailyCaRanksRollout();
  if (!rollout.enabled) {
    throw new HttpsError("failed-precondition", "Daily CA ranks are disabled.");
  }
  if (rollout.adminsOnly) {
    const email = (request.auth.token.email || "").toLowerCase().trim();
    if (!isAdminEmail(email)) {
      throw new HttpsError(
        "permission-denied",
        "Daily CA ranks are in admin preview.",
      );
    }
  }
}

function scoreAnswers(selectedByUuid, correctByUuid) {
  let correct = 0;
  let wrong = 0;
  let unanswered = 0;
  for (const uuid of Object.keys(correctByUuid)) {
    const selected = selectedByUuid[uuid];
    if (selected == null || String(selected).trim() === "") {
      unanswered++;
      continue;
    }
    if (
      String(selected).trim().toLowerCase() ===
      String(correctByUuid[uuid]).trim().toLowerCase()
    ) {
      correct++;
    } else {
      wrong++;
    }
  }
  const points = Number((correct * 2 - wrong * (2 / 3)).toFixed(2));
  return { correct, wrong, unanswered, score: points };
}

function rowSort(a, b) {
  if (b.score !== a.score) return b.score - a.score;
  return a.elapsed_ms - b.elapsed_ms;
}

function percentileFor(air, n) {
  return n <= 1 ? 100 : Number((((n - air) / (n - 1)) * 100).toFixed(2));
}

/** Current AIR among live submits. Cheap aggregation reads, not a full scan. */
async function liveStanding(dateId, score, elapsedMs) {
  const col = dayRef(dateId).collection("submissions");
  const [betterSnap, fasterSnap, totalSnap] = await Promise.all([
    col.where("mode", "==", "live").where("score", ">", score).count().get(),
    col
      .where("mode", "==", "live")
      .where("score", "==", score)
      .where("elapsed_ms", "<", elapsedMs)
      .count()
      .get(),
    col.where("mode", "==", "live").count().get(),
  ]);
  const n = totalSnap.data().count;
  const air = betterSnap.data().count + fasterSnap.data().count + 1;
  return { air, n, percentile: percentileFor(air, n) };
}

async function attachLiveStanding(dateId, payload) {
  if (payload.mode !== "live" || typeof payload.score !== "number") {
    return payload;
  }
  const elapsed =
    typeof payload.elapsed_ms === "number" ? payload.elapsed_ms : 0;
  try {
    const standing = await liveStanding(dateId, payload.score, elapsed);
    return {
      ...payload,
      air: standing.air,
      percentile: standing.percentile,
      participant_count: standing.n,
    };
  } catch (e) {
    console.warn("liveStanding failed", dateId, e);
    return payload;
  }
}

function insertLeaderboardTop(top, row, n) {
  const next = (Array.isArray(top) ? top : [])
    .filter((e) => e && e.uid !== row.uid)
    .map((e) => ({ ...e }));
  next.push(row);
  next.sort(rowSort);
  const trimmed = next.slice(0, 100);
  trimmed.forEach((e, i) => {
    e.air = i + 1;
    e.percentile = percentileFor(e.air, n);
  });
  return trimmed;
}

function submissionPayloadFromData(uid, d) {
  return {
    ok: true,
    already: true,
    mode: d.mode || "live",
    score: d.score || 0,
    correct: d.correct || 0,
    wrong: d.wrong || 0,
    unanswered: d.unanswered || 0,
    elapsed_ms: Number(d.elapsed_ms) || 0,
    air: null,
    percentile: null,
    participant_count: null,
  };
}

async function syncRankDay(iso, questions) {
  const { answers, uuids } = answersFromQuestions(questions);
  await dayRef(iso).collection("private").doc("answers").set({
    answers,
    uuids,
  });
  return { answers, uuids };
}

async function loadAnswers(iso) {
  const answersRef = dayRef(iso).collection("private").doc("answers");
  const snap = await answersRef.get();
  const data = snap.exists ? snap.data() || {} : {};
  if (data.answers && Object.keys(data.answers).length) return data;

  const liveSnap = await liveDocRef(iso).get();
  if (!liveSnap.exists) {
    throw new HttpsError("not-found", "Paper not found.");
  }
  const questions = coerceQuestionList((liveSnap.data() || {}).questions);
  if (!questions.length) {
    throw new HttpsError("failed-precondition", "Paper has no questions.");
  }
  return syncRankDay(iso, questions);
}

async function rerankAllAndFreeze(dateId) {
  const ref = dayRef(dateId);
  const lbRef = ref.collection("meta").doc("leaderboard");
  const [lbSnap, subsSnap] = await Promise.all([
    lbRef.get(),
    ref.collection("submissions").where("mode", "==", "live").get(),
  ]);
  const prevLb = lbSnap.exists ? lbSnap.data() || {} : {};
  if (prevLb.status === "frozen") {
    return { skipped: true, reason: "already_frozen", dateId };
  }
  if (subsSnap.empty && !lbSnap.exists) {
    return { skipped: true, reason: "no_day", dateId };
  }

  const rows = [];
  subsSnap.forEach((doc) => {
    const d = doc.data() || {};
    rows.push({
      uid: doc.id,
      score: Number(d.score) || 0,
      elapsed_ms: Number(d.elapsed_ms) || 0,
      display_name: d.display_name || "",
      correct: d.correct || 0,
      wrong: d.wrong || 0,
      unanswered: d.unanswered || 0,
    });
  });
  rows.sort(rowSort);

  const n = rows.length;
  const qCount = prevLb.question_count || 0;
  const top = rows.slice(0, 100).map((row, i) => {
    const air = i + 1;
    return {
      uid: row.uid,
      display_name: row.display_name,
      score: row.score,
      elapsed_ms: row.elapsed_ms,
      air,
      percentile: percentileFor(air, n),
      correct: row.correct,
      wrong: row.wrong,
      unanswered: row.unanswered,
    };
  });

  await lbRef.set({
    top,
    participant_count: n,
    question_count: qCount,
    status: "frozen",
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  });
  return { ok: true, dateId, participant_count: n };
}

async function freezeDay(iso) {
  const result = await rerankAllAndFreeze(iso);
  if (!result.skipped) {
    console.log("freezeDailyCa", iso, result.participant_count);
  }
  return result;
}

/**
 * 6:00 AM IST — freeze the paper that just stopped being "today's paper".
 * Saturday's board stays live through Monday (no Sunday pack).
 */
exports.freezeDailyCa = onSchedule(
  {
    schedule: "0 6 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
    timeoutSeconds: 120,
  },
  async () => {
    const current = paperQuizContentIso();
    const stateSnap = await ranksStateRef().get();
    const previous =
      (stateSnap.exists && (stateSnap.data() || {}).current_date_id) || null;
    let toFreeze = previous && previous !== current ? previous : null;
    if (!toFreeze && previous == null) {
      const justBefore = istParts(new Date(Date.now() - 60 * 1000));
      const was = paperQuizContentIso(justBefore);
      if (was && was !== current) toFreeze = was;
    }
    if (previous === current) {
      return { skipped: true, reason: "same_paper", previous, current };
    }
    await ranksStateRef().set(
      {
        current_date_id: current || null,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
    if (!toFreeze) {
      return { skipped: true, reason: "first_run", previous, current };
    }
    return freezeDay(toFreeze);
  },
);

exports.adminFreezeDailyCa = onCall(callableOpts, async (request) => {
  requireAdmin(request);
  const iso = String((request.data && request.data.date) || "").trim();
  if (!/^\d{4}-\d{2}-\d{2}$/.test(iso)) {
    throw new HttpsError("invalid-argument", "date must be YYYY-MM-DD.");
  }
  return freezeDay(iso);
});

/**
 * Callable: submitDailyCa
 * data: { dateId, answers: {uuid: 'a'|'b'|...}, elapsedMs, displayName? }
 */
exports.submitDailyCa = onCall(
  { region: "asia-south1" },
  async (request) => {
    await assertDailyCaRankParticipant(request);
    const uid = request.auth.uid;
    const data = request.data || {};
    const dateId = typeof data.dateId === "string" ? data.dateId.trim() : "";
    const elapsedMs = Math.max(
      0,
      Math.min(Number(data.elapsedMs) || 0, MAX_ELAPSED_MS),
    );
    const answers =
      data.answers && typeof data.answers === "object" ? data.answers : null;
    const displayName =
      typeof data.displayName === "string"
        ? data.displayName.trim().slice(0, 60)
        : "";

    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId) || !answers) {
      throw new HttpsError("invalid-argument", "dateId and answers required.");
    }

    const current = paperQuizContentIso();
    const ref = dayRef(dateId);
    const subRef = ref.collection("submissions").doc(uid);
    const lbRef = ref.collection("meta").doc("leaderboard");

    const privateData = await loadAnswers(dateId);
    const correctByUuid = privateData.answers || {};
    if (!Object.keys(correctByUuid).length) {
      throw new HttpsError("failed-precondition", "Answers not ready.");
    }
    const breakdown = scoreAnswers(answers, correctByUuid);
    const qCount = Array.isArray(privateData.uuids)
      ? privateData.uuids.length
      : Object.keys(correctByUuid).length;
    const now = Date.now();

    const result = await db().runTransaction(async (tx) => {
      const existingSnap = await tx.get(subRef);
      const lbSnap = await tx.get(lbRef);
      const existing = existingSnap.exists ? existingSnap.data() || {} : null;
      if (existing && existing.mode === "live") {
        return submissionPayloadFromData(uid, existing);
      }

      const lb = lbSnap.exists ? lbSnap.data() || {} : {};
      const frozen = lb.status === "frozen";
      const mode = !frozen && current === dateId ? "live" : "unranked";
      if (existing && mode === "unranked" && existing.mode === "unranked") {
        return submissionPayloadFromData(uid, existing);
      }

      let participantCount = typeof lb.participant_count === "number"
        ? lb.participant_count
        : 0;

      if (mode === "live") {
        participantCount += 1;
        const row = {
          uid,
          display_name: displayName,
          score: breakdown.score,
          elapsed_ms: elapsedMs,
          correct: breakdown.correct,
          wrong: breakdown.wrong,
          unanswered: breakdown.unanswered,
        };
        const top = insertLeaderboardTop(lb.top, row, participantCount);
        tx.set(lbRef, {
          top,
          participant_count: participantCount,
          question_count: qCount,
          status: "live",
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      tx.set(subRef, {
        mode,
        score: breakdown.score,
        correct: breakdown.correct,
        wrong: breakdown.wrong,
        unanswered: breakdown.unanswered,
        elapsed_ms: elapsedMs,
        answers,
        display_name: displayName,
        submitted_at: admin.firestore.FieldValue.serverTimestamp(),
        submitted_at_ms: now,
      });

      return {
        ok: true,
        already: false,
        mode,
        score: breakdown.score,
        correct: breakdown.correct,
        wrong: breakdown.wrong,
        unanswered: breakdown.unanswered,
        elapsed_ms: elapsedMs,
        participant_count: participantCount || null,
      };
    });

    return attachLiveStanding(dateId, result);
  },
);

/**
 * Public top-100 snapshot. Admin SDK so it works even when client rules
 * still deny daily_ca_days/{dateId}/meta/leaderboard.
 */
exports.getDailyCaLeaderboard = onCall(
  { region: "asia-south1" },
  async (request) => {
    if (!request.auth) {
      throw new HttpsError("unauthenticated", "Sign in required.");
    }
    const dateId =
      typeof request.data?.dateId === "string" ? request.data.dateId.trim() : "";
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId)) {
      throw new HttpsError("invalid-argument", "dateId required.");
    }
    const snap = await dayRef(dateId).collection("meta").doc("leaderboard").get();
    if (!snap.exists) {
      return {
        ok: true,
        date_id: dateId,
        top: [],
        participant_count: 0,
        question_count: 0,
        status: "live",
      };
    }
    const d = snap.data() || {};
    const top = Array.isArray(d.top) ? d.top : [];
    return {
      ok: true,
      date_id: dateId,
      top,
      participant_count: Number(d.participant_count) || top.length,
      question_count: Number(d.question_count) || 0,
      status: typeof d.status === "string" ? d.status : "live",
    };
  },
);

/**
 * Current AIR for the signed-in user. Computed on read so it moves as
 * others finish — not a stamp from submit time.
 */
exports.getDailyCaMyRank = onCall(
  { region: "asia-south1" },
  async (request) => {
    await assertDailyCaRankParticipant(request);
    const uid = request.auth.uid;
    const dateId =
      typeof request.data?.dateId === "string" ? request.data.dateId.trim() : "";
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId)) {
      throw new HttpsError("invalid-argument", "dateId required.");
    }
    const snap = await dayRef(dateId).collection("submissions").doc(uid).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "No submission for this paper.");
    }
    const d = snap.data() || {};
    const base = {
      ok: true,
      mode: d.mode || "live",
      score: d.score || 0,
      correct: d.correct || 0,
      wrong: d.wrong || 0,
      unanswered: d.unanswered || 0,
      elapsed_ms: Number(d.elapsed_ms) || 0,
      display_name: d.display_name || "",
    };
    return attachLiveStanding(dateId, base);
  },
);

exports._dailyCaRankInternals = {
  paperQuizContentIso,
  scoreAnswers,
  answersFromQuestions,
  insertLeaderboardTop,
  freezeDay,
};
