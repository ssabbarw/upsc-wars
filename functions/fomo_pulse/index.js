/**
 * FOMO Pulse — breaking-news push MCQs.
 *
 * Cost-conscious Firestore design:
 *   fomo_pulses/{pulseId}           — pulse + embedded question + aggregate counters
 *   fomo_pulse_user_state/{uid}     — ONE doc per user: compact attempt map (1 read/history)
 *
 * Reads per user action:
 *   History page:  1 query (≤20 pulses) + 1 user-state doc = ≤21 reads
 *   Pulse detail:  1 pulse doc (skip if cached from list)
 *   Attempt:       callable only (server-side transaction, no client pulse re-read)
 *
 * Writes per attempt: 1 pulse aggregate update + 1 user-state merge = 2 writes
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const crypto = require("crypto");
const fs = require("fs");
const path = require("path");

const REGION = "asia-south1";
const PULSES = "fomo_pulses";
const USER_STATE = "fomo_pulse_user_state";
const DRAFTS = "daily_ca_drafts";
const MAX_TITLE = 120;
const MAX_BODY = 180;
const MIN_STATS_ATTEMPTS = 20;
const PULSE_TTL_MS = 48 * 60 * 60 * 1000;
const HISTORY_LIMIT = 20;
const HAIKU_MODEL = process.env.HAIKU_MODEL || "claude-haiku-4-5-20251001";
const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

/** Must match Flutter [FomoPulseConstants.broadcastFcmTopic]. */
const FOMO_PULSE_FCM_TOPIC = "upsc_wars_fomo_pulse";

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

function pulseBroadcastAllowlist() {
  const raw = process.env.SPOT_TEST_BROADCAST_EMAILS || "";
  return new Set(
    raw
      .split(",")
      .map((e) => e.trim().toLowerCase())
      .filter(Boolean),
  );
}

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

function requireSignedIn(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  return request.auth.uid;
}

function formatIsoDate(ist) {
  const y = ist.getUTCFullYear();
  const m = String(ist.getUTCMonth() + 1).padStart(2, "0");
  const d = String(ist.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

function istNow() {
  return new Date(Date.now() + IST_OFFSET_MS);
}

function loadPrompt(name) {
  return fs.readFileSync(path.join(__dirname, name), "utf8").trim();
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

async function anthropicJson(system, userContent) {
  const key = process.env.ANTHROPIC_API_KEY;
  if (!key) {
    throw new HttpsError(
      "failed-precondition",
      "ANTHROPIC_API_KEY is not set on Cloud Functions.",
    );
  }
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": key,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: HAIKU_MODEL,
      max_tokens: 4096,
      system,
      messages: [{ role: "user", content: userContent }],
    }),
  });
  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Anthropic ${res.status}: ${body.slice(0, 400)}`);
  }
  const json = await res.json();
  const text = (json.content || [])
    .filter((b) => b.type === "text")
    .map((b) => b.text)
    .join("");
  return parseJsonFromText(text);
}

function stripHtml(html) {
  return String(html || "")
    .replace(/<script[\s\S]*?<\/script>/gi, " ")
    .replace(/<style[\s\S]*?<\/style>/gi, " ")
    .replace(/<[^>]+>/g, " ")
    .replace(/\s+/g, " ")
    .trim();
}

async function fetchUrlText(url) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), 12000);
  try {
    const res = await fetch(url, {
      signal: controller.signal,
      headers: {
        "user-agent":
          "Mozilla/5.0 (compatible; UPSCWarsPulse/1.0; +https://upscwars.com)",
        accept: "text/html,application/xhtml+xml,text/plain;q=0.9,*/*;q=0.8",
      },
      redirect: "follow",
    });
    if (!res.ok) {
      throw new Error(`HTTP ${res.status}`);
    }
    const ct = (res.headers.get("content-type") || "").toLowerCase();
    const body = await res.text();
    if (ct.includes("html")) {
      const text = stripHtml(body);
      return text.slice(0, 12000);
    }
    return body.slice(0, 12000);
  } finally {
    clearTimeout(timer);
  }
}

function questionPreview(en) {
  const display = (en.display_text || "").toString().trim();
  if (display) return display.slice(0, 200);
  const stem = (en.stem || "").toString().trim();
  return stem.slice(0, 200) || "MCQ";
}

function harvestCandidateFromQuestion(q, index) {
  const meta = q.meta && typeof q.meta === "object" ? q.meta : {};
  const en = q.en && typeof q.en === "object" ? q.en : {};
  const importance = Number(meta.news_importance) || 3;
  const sourceUrl = (meta.source_url || meta.news_source_url || "").toString().trim();
  const trigger = (meta.news_trigger || meta.topic || "").toString().trim();
  const summary = (meta.news_summary || "").toString().trim();
  const draftId = (q.draft_id || q.uuid || `d${index + 1}`).toString();
  return {
    draft_id: draftId,
    title: trigger || questionPreview(en).slice(0, 80),
    preview: questionPreview(en),
    gs_subject: (meta.gs_subject || "").toString(),
    source_url: sourceUrl,
    news_importance: importance,
    news_summary: summary,
  };
}

function normalizeQuestion(raw, fallbackUrl) {
  const q = raw && typeof raw === "object" ? raw : {};
  const en = q.en && typeof q.en === "object" ? q.en : {};
  const shared = q.shared && typeof q.shared === "object" ? q.shared : {};
  const meta = q.meta && typeof q.meta === "object" ? q.meta : {};
  const correct = String(shared.correct_option || "a")
    .trim()
    .toLowerCase()
    .slice(0, 1);
  if (!["a", "b", "c", "d"].includes(correct)) {
    throw new HttpsError("invalid-argument", "Invalid correct_option.");
  }
  const display = (en.display_text || "").toString().trim();
  const opts = ["a", "b", "c", "d"].map((k) =>
    (en[`option_${k}`] || "").toString().trim(),
  );
  if (!display && opts.every((o) => !o)) {
    throw new HttpsError("invalid-argument", "Question text is required.");
  }
  if (fallbackUrl && !meta.source_url) {
    meta.source_url = fallbackUrl;
  }
  return {
    en: {
      display_text: display,
      option_a: opts[0],
      option_b: opts[1],
      option_c: opts[2],
      option_d: opts[3],
      final_explanation: (en.final_explanation || "").toString().trim(),
    },
    shared: {
      correct_option: correct,
      question_type: (shared.question_type || "direct").toString(),
    },
    meta,
  };
}

const callableOpts = {
  region: REGION,
  timeoutSeconds: 120,
  memory: "512MiB",
  secrets: ["ANTHROPIC_API_KEY"],
};

const generateOpts = {
  ...callableOpts,
  timeoutSeconds: 180,
};

/**
 * Admin: list harvest candidates from today's (or yesterday's) CA draft.
 * Cost: 1–2 Firestore reads.
 */
exports.listFomoPulseHarvestCandidates = onCall(callableOpts, async (request) => {
  requireAdmin(request);
  const dates = [formatIsoDate(istNow())];
  const yesterday = new Date(istNow().getTime() - 24 * 60 * 60 * 1000);
  dates.push(formatIsoDate(yesterday));

  for (const iso of dates) {
    const snap = await db().collection(DRAFTS).doc(iso).get();
    if (!snap.exists) continue;
    const data = snap.data() || {};
    const questions = Array.isArray(data.questions) ? data.questions : [];
    if (questions.length === 0) continue;
    const candidates = questions
      .map((q, i) => harvestCandidateFromQuestion(q, i))
      .filter((c) => c.title || c.preview)
      .sort((a, b) => b.news_importance - a.news_importance);
    return { ok: true, draft_date: iso, candidates };
  }
  return { ok: true, draft_date: null, candidates: [] };
});

/**
 * Admin: generate pulse draft from URL or harvest item.
 * Cost: 0 Firestore writes (draft returned to client only).
 */
exports.generateFomoPulseDraft = onCall(generateOpts, async (request) => {
  requireAdmin(request);
  const data = request.data || {};
  const source = String(data.source || "").trim().toLowerCase();

  if (source === "harvest") {
    const draftDate = String(data.draft_date || "").trim();
    const draftId = String(data.draft_id || "").trim();
    if (!draftDate || !draftId) {
      throw new HttpsError("invalid-argument", "draft_date and draft_id required.");
    }
    const snap = await db().collection(DRAFTS).doc(draftDate).get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Draft not found.");
    }
    const questions = Array.isArray(snap.data().questions)
      ? snap.data().questions
      : [];
    const q = questions.find(
      (item, i) =>
        String(item.draft_id || item.uuid || `d${i + 1}`) === draftId,
    );
    if (!q) {
      throw new HttpsError("not-found", "Question not found in draft.");
    }
    const meta = q.meta || {};
    const en = q.en || {};
    const hookInput = {
      news_trigger: meta.news_trigger || meta.topic || "",
      news_summary: meta.news_summary || "",
      gs_subject: meta.gs_subject || "",
      source_url: meta.source_url || "",
      question_preview: questionPreview(en),
    };
    const hooks = await anthropicJson(
      loadPrompt("pulse_hook_system.txt"),
      JSON.stringify(hookInput),
    );
    if (hooks.error) {
      throw new HttpsError("failed-precondition", String(hooks.error));
    }
    return {
      ok: true,
      draft: {
        notification_title: (hooks.notification_title || "").slice(0, MAX_TITLE),
        notification_body: (hooks.notification_body || "").slice(0, MAX_BODY),
        news_summary: (meta.news_summary || "").toString(),
        source_url: (meta.source_url || "").toString(),
        question: normalizeQuestion(q, meta.source_url),
        harvest: { draft_date: draftDate, draft_id: draftId },
      },
    };
  }

  if (source === "url") {
    const url = String(data.url || "").trim();
    if (!url || !/^https?:\/\//i.test(url)) {
      throw new HttpsError("invalid-argument", "Valid http(s) URL required.");
    }
    let articleText = "";
    try {
      articleText = await fetchUrlText(url);
    } catch (e) {
      throw new HttpsError(
        "failed-precondition",
        `Could not fetch URL: ${e.message || e}`,
      );
    }
    if (!articleText || articleText.length < 100) {
      throw new HttpsError(
        "failed-precondition",
        "URL returned too little text. Try a different source or use harvest.",
      );
    }
    const generated = await anthropicJson(
      loadPrompt("pulse_generate_system.txt"),
      JSON.stringify({ url, article_text: articleText.slice(0, 10000) }),
    );
    if (generated.error) {
      throw new HttpsError("failed-precondition", String(generated.error));
    }
    return {
      ok: true,
      draft: {
        notification_title: (generated.notification_title || "").slice(
          0,
          MAX_TITLE,
        ),
        notification_body: (generated.notification_body || "").slice(
          0,
          MAX_BODY,
        ),
        news_summary: (generated.news_summary || "").toString(),
        source_url: url,
        question: normalizeQuestion(generated.question, url),
        harvest: null,
      },
    };
  }

  throw new HttpsError("invalid-argument", 'source must be "url" or "harvest".');
});

/**
 * Admin: persist pulse + send FCM (self or broadcast).
 * Cost: 2 Firestore writes (pulse + notification analytics).
 */
exports.sendFomoPulseNotification = onCall(callableOpts, async (request) => {
  const email = requireAdmin(request);
  const data = request.data || {};
  const title = String(data.title || "").trim().slice(0, MAX_TITLE);
  const body = String(data.body || "").trim().slice(0, MAX_BODY);
  if (!title || !body) {
    throw new HttpsError("invalid-argument", "title and body required.");
  }
  let question;
  try {
    question = normalizeQuestion(data.question, data.source_url);
  } catch (e) {
    if (e instanceof HttpsError) throw e;
    throw new HttpsError("invalid-argument", "Invalid question payload.");
  }
  const target =
    String(data.target || "self").trim().toLowerCase() === "broadcast"
      ? "broadcast"
      : "self";

  const pulseId = crypto.randomUUID();
  const notificationId = pulseId;
  const now = admin.firestore.Timestamp.now();
  const expiresAt = admin.firestore.Timestamp.fromMillis(
    Date.now() + PULSE_TTL_MS,
  );

  const pulseDoc = {
    pulse_id: pulseId,
    status: "sent",
    title,
    body,
    news_summary: String(data.news_summary || "").trim(),
    source_url: String(data.source_url || question.meta.source_url || "").trim(),
    question,
    sent_at: now,
    expires_at: expiresAt,
    attempt_count: 0,
    correct_count: 0,
    created_by: email,
    notification_id: notificationId,
    harvest: data.harvest || null,
  };

  await db().collection(PULSES).doc(pulseId).set(pulseDoc);

  const fcmData = {
    kind: "fomo_pulse",
    pulse_id: pulseId,
    notification_id: notificationId,
  };
  const message = {
    notification: { title, body },
    data: fcmData,
  };

  await db()
    .collection("admin_dashboard")
    .doc("notifications")
    .collection("items")
    .doc(notificationId)
    .set(
      {
        kind: "fomo_pulse",
        title,
        pulse_id: pulseId,
        sent_at: admin.firestore.FieldValue.serverTimestamp(),
        opens: 0,
        conversions: 0,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );

  if (target === "broadcast") {
    const allowlist = pulseBroadcastAllowlist();
    if (!allowlist.has(email)) {
      return { ok: false, reason: "not_authorized", pulseId };
    }
    await admin.messaging().send({
      topic: FOMO_PULSE_FCM_TOPIC,
      ...message,
    });
    return { ok: true, target: "broadcast", pulseId, notificationId };
  }

  const userSnap = await db().collection("users").doc(email).get();
  const token = userSnap.exists ? userSnap.data().fcm_token : null;
  if (!token || typeof token !== "string" || !token.trim()) {
    return { ok: false, reason: "no_token", pulseId };
  }
  try {
    await admin.messaging().send({ token: token.trim(), ...message });
  } catch (e) {
    console.error("sendFomoPulseNotification FCM failed", e);
    return { ok: false, reason: "send_failed", pulseId };
  }
  return { ok: true, target: "self", pulseId, notificationId };
});

/**
 * User: submit one attempt. Idempotent per user per pulse.
 * Cost: 1 transaction (2 writes max).
 */
exports.submitFomoPulseAttempt = onCall(
  { region: REGION, timeoutSeconds: 30 },
  async (request) => {
    const uid = requireSignedIn(request);
    const data = request.data || {};
    const pulseId = String(data.pulse_id || "").trim();
    const selected = String(data.selected_option || "")
      .trim()
      .toLowerCase()
      .slice(0, 1);
    const timeSpent = Math.max(
      0,
      Math.min(600, Number(data.time_spent_secs) || 0),
    );

    if (!pulseId) {
      throw new HttpsError("invalid-argument", "pulse_id required.");
    }
    if (!["a", "b", "c", "d"].includes(selected)) {
      throw new HttpsError("invalid-argument", "selected_option must be a–d.");
    }

    const pulseRef = db().collection(PULSES).doc(pulseId);
    const stateRef = db().collection(USER_STATE).doc(uid);

    const result = await db().runTransaction(async (tx) => {
      const pulseSnap = await tx.get(pulseRef);
      if (!pulseSnap.exists) {
        throw new HttpsError("not-found", "Pulse not found.");
      }
      const pulse = pulseSnap.data() || {};
      if (pulse.status !== "sent") {
        throw new HttpsError("failed-precondition", "Pulse is not active.");
      }
      const expiresAt = pulse.expires_at;
      if (
        expiresAt &&
        expiresAt.toMillis &&
        expiresAt.toMillis() < Date.now()
      ) {
        throw new HttpsError("failed-precondition", "Pulse has expired.");
      }

      const stateSnap = await tx.get(stateRef);
      const state = stateSnap.exists ? stateSnap.data() || {} : {};
      const attempts =
        state.attempts && typeof state.attempts === "object"
          ? { ...state.attempts }
          : {};

      if (attempts[pulseId]) {
        const prev = attempts[pulseId];
        return {
          already_attempted: true,
          is_correct: prev.c === true,
          selected_option: prev.o || selected,
          time_spent_secs: prev.t || timeSpent,
          attempt_count: pulse.attempt_count || 0,
          correct_count: pulse.correct_count || 0,
        };
      }

      const correctOpt = String(
        pulse.question?.shared?.correct_option || "a",
      )
        .trim()
        .toLowerCase()
        .slice(0, 1);
      const isCorrect = selected === correctOpt;

      attempts[pulseId] = {
        o: selected,
        c: isCorrect,
        t: timeSpent,
        at: admin.firestore.FieldValue.serverTimestamp(),
      };

      tx.set(
        stateRef,
        {
          attempts,
          updated_at: admin.firestore.FieldValue.serverTimestamp(),
        },
        { merge: true },
      );

      tx.update(pulseRef, {
        attempt_count: admin.firestore.FieldValue.increment(1),
        correct_count: admin.firestore.FieldValue.increment(isCorrect ? 1 : 0),
      });

      const attemptCount = (pulse.attempt_count || 0) + 1;
      const correctCount = (pulse.correct_count || 0) + (isCorrect ? 1 : 0);

      return {
        already_attempted: false,
        is_correct: isCorrect,
        selected_option: selected,
        correct_option: correctOpt,
        time_spent_secs: timeSpent,
        attempt_count: attemptCount,
        correct_count: correctCount,
      };
    });

    const attemptCount = result.attempt_count || 0;
    const correctCount = result.correct_count || 0;
    const showStats = attemptCount >= MIN_STATS_ATTEMPTS;
    return {
      ok: true,
      ...result,
      stats: showStats
        ? {
            attempt_count: attemptCount,
            correct_pct: Math.round((correctCount / attemptCount) * 100),
          }
        : null,
    };
  },
);

/** Export constants for tests / docs. */
exports._fomoPulseConstants = {
  MIN_STATS_ATTEMPTS,
  HISTORY_LIMIT,
  FOMO_PULSE_FCM_TOPIC,
};
