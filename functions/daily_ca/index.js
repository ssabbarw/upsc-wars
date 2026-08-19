/**
 * Daily CA admin flow — drafts, publish, auto-publish, notify.
 *
 * Firestore:
 *   daily_ca_drafts/{YYYY-MM-DD}
 *   daily_mcqs/{YYYY}/{MM}/{DD}
 */
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");
const tls = require("tls");

const llmAdmin = require("../llm_admin");
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;
const DRAFTS = "daily_ca_drafts";
const LIVE = "daily_mcqs";
const PUBLISH_MIN = 5;
const PUBLISH_MAX = 10;
const ADMIN_EMAIL = (
  process.env.ADMIN_NOTIFY_EMAIL || "sachinsabbarwal@gmail.com"
)
  .trim()
  .toLowerCase();

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

function parseJsonFromText(text) {
  const raw = String(text || "").trim();
  const fence = raw.indexOf("```");
  let payload = raw;
  if (fence !== -1) {
    let after = raw.slice(fence + 3);
    if (after.startsWith("json")) after = after.slice(4);
    const end = after.indexOf("```");
    payload = (end === -1 ? after : after.slice(0, end)).trim();
  }
  const start = payload.search(/[\[{]/);
  if (start < 0) throw new Error("No JSON in model output");
  return JSON.parse(payload.slice(start));
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

exports.adminAutoPublishDailyCa = onCall(publishOpts, async (request) => {
  requireAdmin(request);
  const iso =
    String((request.data && request.data.date) || "").trim() ||
    yesterdayIso(istParts());
  return autoPublishForIso(iso);
});
