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

const llmAdmin = require("../llm_admin");
const { parseJsonFromText } = require("../parse_llm_json");
const REGION = "asia-south1";
const PULSES = "fomo_pulses";
const USER_STATE = "fomo_pulse_user_state";
const DRAFTS = "daily_ca_drafts";
const MAX_TITLE = 120;
const MAX_BODY = 180;
const MIN_STATS_ATTEMPTS = 20;
const PULSE_TTL_MS = 48 * 60 * 60 * 1000;
const HISTORY_LIMIT = 20;
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

async function anthropicJson(system, userContent, requestedModel) {
  const cfg = await llmAdmin.loadLlmConfig();
  const model = llmAdmin.normalizeModel(
    requestedModel || cfg.shotsModel,
    llmAdmin.DEFAULT_SHOTS_MODEL,
  );
  const { text } = await llmAdmin.anthropicJson({
    system,
    userContent,
    model,
    apiKey: cfg.shotsApiKey,
  });
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

function metaContent(html, keys) {
  const raw = String(html || "");
  for (const key of keys) {
    const escaped = key.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
    const patterns = [
      new RegExp(
        `<meta[^>]+(?:property|name)=["']${escaped}["'][^>]*content=["']([^"']+)["']`,
        "i",
      ),
      new RegExp(
        `<meta[^>]+content=["']([^"']+)["'][^>]*(?:property|name)=["']${escaped}["']`,
        "i",
      ),
    ];
    for (const re of patterns) {
      const m = raw.match(re);
      if (m && m[1]) return m[1].trim();
    }
  }
  return "";
}

function resolveUrl(maybeRelative, pageUrl) {
  const value = String(maybeRelative || "").trim();
  if (!value) return "";
  try {
    return new URL(value, pageUrl).toString();
  } catch (_) {
    return "";
  }
}

function siteNameFromUrl(pageUrl) {
  try {
    const host = new URL(pageUrl).hostname.replace(/^www\./i, "");
    return host;
  } catch (_) {
    return "";
  }
}

function extractPageMeta(html, pageUrl) {
  const imageRaw = metaContent(html, [
    "og:image",
    "og:image:url",
    "twitter:image",
    "twitter:image:src",
  ]);
  const site =
    metaContent(html, ["og:site_name"]) || siteNameFromUrl(pageUrl);
  return {
    image_url: resolveUrl(imageRaw, pageUrl),
    image_source: site,
    og_title: metaContent(html, ["og:title", "twitter:title"]),
    og_description: metaContent(html, [
      "og:description",
      "twitter:description",
      "description",
    ]),
  };
}

const BROWSER_UAS = [
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/127.0.0.0 Safari/537.36",
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 14_5) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.5 Safari/605.1.15",
];

async function fetchWithUa(url, userAgent, timeoutMs = 12000) {
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    return await fetch(url, {
      signal: controller.signal,
      headers: {
        "user-agent": userAgent,
        accept:
          "text/html,application/xhtml+xml,application/xml;q=0.9,text/plain;q=0.8,*/*;q=0.7",
        "accept-language": "en-IN,en;q=0.9",
        "cache-control": "no-cache",
      },
      redirect: "follow",
    });
  } finally {
    clearTimeout(timer);
  }
}

async function fetchViaJinaReader(url) {
  const readerUrl = `https://r.jina.ai/http://${url.replace(/^https?:\/\//i, "")}`;
  const res = await fetchWithUa(readerUrl, BROWSER_UAS[0], 20000);
  if (!res.ok) {
    throw new Error(`Jina reader HTTP ${res.status}`);
  }
  const body = await res.text();
  return {
    text: stripHtml(body).slice(0, 12000),
    image_url: "",
    image_source: siteNameFromUrl(url),
    og_title: "",
    og_description: "",
  };
}

async function fetchUrlPage(url) {
  let lastErr = null;
  for (const ua of BROWSER_UAS) {
    try {
      const res = await fetchWithUa(url, ua);
      if (res.status === 429 || res.status === 403) {
        lastErr = new Error(`HTTP ${res.status}`);
        continue;
      }
      if (!res.ok) {
        throw new Error(`HTTP ${res.status}`);
      }
      const ct = (res.headers.get("content-type") || "").toLowerCase();
      const body = await res.text();
      const meta = extractPageMeta(body, url);
      if (ct.includes("html")) {
        return {
          text: stripHtml(body).slice(0, 12000),
          ...meta,
        };
      }
      return { text: body.slice(0, 12000), ...meta };
    } catch (e) {
      lastErr = e;
    }
  }
  if (String(lastErr && lastErr.message).includes("HTTP 429")) {
    try {
      return await fetchViaJinaReader(url);
    } catch (readerErr) {
      throw new Error(
        `HTTP 429 (site blocked fetch); fallback failed: ${readerErr.message || readerErr}`,
      );
    }
  }
  throw lastErr || new Error("Could not fetch URL");
}

async function fetchUrlText(url) {
  const page = await fetchUrlPage(url);
  return page.text;
}

function normalizePoints(raw) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((p) => String(p || "").trim())
    .filter(Boolean)
    .slice(0, 3);
}

function normalizeSendFlag(raw, fallback = true) {
  if (raw === undefined || raw === null) return fallback;
  if (typeof raw === "boolean") return raw;
  const s = String(raw).trim().toLowerCase();
  if (["false", "0", "no"].includes(s)) return false;
  if (["true", "1", "yes"].includes(s)) return true;
  return fallback;
}

function nestedObject(raw, key) {
  return raw && typeof raw === "object" && raw[key] && typeof raw[key] === "object"
    ? raw[key]
    : {};
}

function pickCopyField(raw, keys) {
  if (!raw || typeof raw !== "object") return "";
  const shot = nestedObject(raw, "ca_shot");
  const notification = nestedObject(raw, "notification");
  for (const key of keys) {
    const value = raw[key] || shot[key] || notification[key];
    const text = String(value || "").trim();
    if (text) return text;
  }
  return "";
}

function asText(value) {
  return typeof value === "string" ? value.trim() : "";
}

/** Drop a leading "What happened:" / "क्या हुआ:" so the briefing starts with the news. */
function cleanNewsSummary(text) {
  return asText(text).replace(
    /^\*{0,2}\s*(what happened|क्या हुआ)\s*:?\s*\*{0,2}\s*/i,
    "",
  ).trim();
}

function formatNewsSummary(raw) {
  if (typeof raw === "string") return cleanNewsSummary(raw);
  if (!raw || typeof raw !== "object") return "";
  return cleanNewsSummary(
    asText(raw.news_summary) || asText(nestedObject(raw, "ca_shot").news_summary),
  );
}

function formatHeadline(raw, fallback = "") {
  const fromCopy = pickCopyField(raw, ["headline"]);
  if (fromCopy) return fromCopy;
  return String(fallback || "").trim();
}

function formatNotificationTitle(raw) {
  return pickCopyField(raw, ["notification_title", "title"]);
}

function formatNotificationBody(raw) {
  return pickCopyField(raw, ["notification_body", "body"]);
}

function formatLearnableTopics(raw) {
  if (!raw || typeof raw !== "object") return [];
  const shot = nestedObject(raw, "ca_shot");
  const summary =
    raw.news_summary && typeof raw.news_summary === "object"
      ? raw.news_summary
      : {};
  return normalizePoints(
    raw.upsc_points ||
      shot.learnable_topics ||
      summary.learn ||
      summary.topics_to_learn ||
      (shot.why_upsc ? [shot.why_upsc] : []),
  );
}

function normalizeStringArray(raw, max = 6) {
  if (!Array.isArray(raw)) return [];
  return raw
    .map((v) => String(v || "").trim())
    .filter(Boolean)
    .slice(0, max);
}

function normalizeStatementAnalysis(raw) {
  if (!Array.isArray(raw)) return [];
  const out = [];
  for (const item of raw) {
    if (!item || typeof item !== "object") continue;
    const statement = String(item.statement || item.label || "").trim();
    const reason = String(item.reason || "").trim();
    const verdict = item.is_correct ?? item.correct ?? item.verdict;
    const isCorrect =
      verdict === true ||
      String(verdict || "")
        .trim()
        .toLowerCase() === "true" ||
      String(verdict || "")
        .trim()
        .toLowerCase() === "correct";
    if (!statement && !reason) continue;
    out.push({
      statement,
      is_correct: isCorrect,
      reason,
    });
  }
  return out.slice(0, 8);
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
  const points = normalizePoints(
    meta.key_facts || meta.upsc_points || (meta.concept_to_test ? [meta.concept_to_test] : []),
  );
  return {
    draft_id: draftId,
    title: trigger || questionPreview(en).slice(0, 80),
    preview: questionPreview(en),
    gs_subject: (meta.gs_subject || "").toString(),
    source_url: sourceUrl,
    news_importance: importance,
    news_summary: summary,
    upsc_points: points,
  };
}

function stripInlineOptionsFromDisplay(display, opts) {
  const text = (display || "").toString().trim();
  if (!text || opts.every((o) => !o)) return text;

  const marker = /^\s*[\(\[]([a-dA-D])[\)\]]\s+/gm;
  const matches = [...text.matchAll(marker)];
  if (matches.length >= 4 && matches[0].index != null) {
    const stem = text.substring(0, matches[0].index).trim();
    if (stem) return stem;
  }

  const inline = text.match(/\s*[\(\[]([aA])[\)\]]\s+/);
  if (inline && inline.index != null) {
    return text.substring(0, inline.index).trim();
  }
  return text;
}

function normalizeQuestion(raw, fallbackUrl) {
  const q = raw && typeof raw === "object" ? raw : {};
  const en =
    q.en && typeof q.en === "object" ? q.en : q;
  const shared =
    q.shared && typeof q.shared === "object"
      ? q.shared
      : {
          correct_option: q.correct_option,
          question_type: q.question_type,
        };
  const meta = q.meta && typeof q.meta === "object" ? { ...q.meta } : {};
  const correct = String(shared.correct_option || "a")
    .trim()
    .toLowerCase()
    .slice(0, 1);
  if (!["a", "b", "c", "d"].includes(correct)) {
    throw new HttpsError("invalid-argument", "Invalid correct_option.");
  }
  const displayRaw = (en.display_text || en.stem || "").toString().trim();
  const opts = ["a", "b", "c", "d"].map((k) =>
    (en[`option_${k}`] || "").toString().trim(),
  );
  const display = stripInlineOptionsFromDisplay(displayRaw, opts);
  if (!display && opts.every((o) => !o)) {
    throw new HttpsError(
      "invalid-argument",
      "Question text is required (display_text or stem + options).",
    );
  }
  if (fallbackUrl && !meta.source_url) {
    meta.source_url = fallbackUrl;
  }
  const hi = q.hi && typeof q.hi === "object" ? q.hi : null;
  const strongDistractor = String(
    en.strong_distractor ||
      en.strongDistractor ||
      q.strong_distractor ||
      q.strongDistractor ||
      "",
  ).trim();
  const eliminationLogic = normalizeStringArray(
    en.elimination_logic ||
      en.eliminationLogic ||
      q.elimination_logic ||
      q.eliminationLogic,
    6,
  );
  const trapExplanation = String(
    en.upsc_trap_explanation ||
      en.upscTrapExplanation ||
      q.upsc_trap_explanation ||
      q.upscTrapExplanation ||
      "",
  ).trim();
  const statementAnalysis = normalizeStatementAnalysis(
    en.statement_analysis ||
      en.statementAnalysis ||
      q.statement_analysis ||
      q.statementAnalysis,
  );
  return {
    en: {
      display_text: display,
      option_a: opts[0],
      option_b: opts[1],
      option_c: opts[2],
      option_d: opts[3],
      strong_distractor: strongDistractor,
      elimination_logic: eliminationLogic,
      upsc_trap_explanation: trapExplanation,
      statement_analysis: statementAnalysis,
      final_explanation: (en.final_explanation || "").toString().trim(),
    },
    shared: {
      correct_option: correct,
      question_type: (shared.question_type || "direct").toString().trim() || "direct",
    },
    meta,
    ...(hi
      ? {
          hi: {
            ...hi,
            strong_distractor: String(
              hi.strong_distractor || hi.strongDistractor || "",
            ).trim(),
            elimination_logic: normalizeStringArray(
              hi.elimination_logic || hi.eliminationLogic,
              6,
            ),
            upsc_trap_explanation: String(
              hi.upsc_trap_explanation || hi.upscTrapExplanation || "",
            ).trim(),
            statement_analysis: normalizeStatementAnalysis(
              hi.statement_analysis || hi.statementAnalysis,
            ),
          },
        }
      : {}),
  };
}

function toHttpsError(e, fallback = "Pulse generation failed.") {
  if (e instanceof HttpsError) return e;
  const message = String(e && e.message ? e.message : e).slice(0, 500);
  return new HttpsError("failed-precondition", message || fallback);
}

function hasQuestionHindi(question) {
  return !!(
    question &&
    question.hi &&
    String(question.hi.display_text || "").trim()
  );
}

function textField(raw) {
  return String(raw || "").trim();
}

/**
 * EN → HI for headline, news_summary, upsc_points, and question text.
 */
async function attachHindi({
  question,
  newsSummary,
  upscPoints,
  sourceUrl,
  headline = "",
  newsSummaryHi = "",
  upscPointsHi = [],
  headlineHi = "",
  requestedModel,
  force = false,
}) {
  const normalized = normalizeQuestion(question, sourceUrl);
  const existingSummaryHi = cleanNewsSummary(newsSummaryHi);
  const existingPointsHi = normalizePoints(upscPointsHi);
  const existingHeadlineHi = textField(headlineHi);
  if (
    !force &&
    hasQuestionHindi(normalized) &&
    existingSummaryHi &&
    existingHeadlineHi
  ) {
    return {
      question: normalized,
      headline_hi: existingHeadlineHi,
      news_summary_hi: existingSummaryHi,
      upsc_points_hi: existingPointsHi,
    };
  }

  const briefingPayload = {
    headline: textField(headline),
    news_summary: cleanNewsSummary(newsSummary),
    upsc_points: normalizePoints(upscPoints),
  };

  if (!force && hasQuestionHindi(normalized) && !existingSummaryHi) {
    const summaryOnly = await anthropicJson(
      loadPrompt("pulse_translate_system.txt"),
      JSON.stringify(briefingPayload),
      requestedModel,
    );
    return {
      question: normalized,
      headline_hi: textField(summaryOnly.headline),
      news_summary_hi: cleanNewsSummary(summaryOnly.news_summary),
      upsc_points_hi: normalizePoints(summaryOnly.upsc_points),
    };
  }

  const hi = await anthropicJson(
    loadPrompt("pulse_translate_system.txt"),
    JSON.stringify({
      ...(normalized.en || {}),
      ...briefingPayload,
    }),
    requestedModel,
  );
  normalized.hi = {
    display_text: textField(hi.display_text),
    option_a: textField(hi.option_a),
    option_b: textField(hi.option_b),
    option_c: textField(hi.option_c),
    option_d: textField(hi.option_d),
    strong_distractor: textField(hi.strong_distractor),
    elimination_logic: normalizeStringArray(hi.elimination_logic, 6),
    upsc_trap_explanation: textField(hi.upsc_trap_explanation),
    statement_analysis: normalizeStatementAnalysis(hi.statement_analysis),
    final_explanation: textField(hi.final_explanation),
  };
  return {
    question: normalized,
    headline_hi: textField(hi.headline) || existingHeadlineHi,
    news_summary_hi: cleanNewsSummary(hi.news_summary) || existingSummaryHi,
    upsc_points_hi: normalizePoints(hi.upsc_points).length
      ? normalizePoints(hi.upsc_points)
      : existingPointsHi,
  };
}

const callableOpts = {
  region: REGION,
  timeoutSeconds: 120,
  memory: "512MiB",
  secrets: ["ANTHROPIC_API_KEY"],
};

/** Generate + Hindi translate can be two LLM calls. */
const generateOpts = {
  ...callableOpts,
  timeoutSeconds: 300,
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

const previewOpts = {
  region: REGION,
  timeoutSeconds: 30,
  memory: "256MiB",
};

/**
 * Admin: og:image + title from article URL. No LLM.
 */
exports.previewFomoPulseArticle = onCall(previewOpts, async (request) => {
  requireAdmin(request);
  const url = String((request.data && request.data.url) || "").trim();
  if (!url || !/^https?:\/\//i.test(url)) {
    throw new HttpsError("invalid-argument", "Valid http(s) URL required.");
  }
  try {
    const page = await fetchUrlPage(url);
    return {
      ok: true,
      image_url: page.image_url || "",
      image_source: page.image_source || "",
      og_title: page.og_title || "",
      og_description: page.og_description || "",
    };
  } catch (e) {
    return {
      ok: false,
      reason: String(e.message || e),
      image_url: "",
      image_source: "",
      og_title: "",
      og_description: "",
    };
  }
});

exports.generateFomoPulseDraft = onCall(generateOpts, async (request) => {
  requireAdmin(request);
  const data = request.data || {};
  const source = String(data.source || "").trim().toLowerCase();
  const requestedModel = String(data.model || "").trim();

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
      requestedModel,
    );
    if (hooks.error) {
      throw new HttpsError("failed-precondition", String(hooks.error));
    }
    const sourceUrl = (meta.source_url || "").toString();
    let imageUrl = String(data.image_url || "").trim();
    let imageSource = String(data.image_source || "").trim();
    if ((!imageUrl || !imageSource) && sourceUrl && /^https?:\/\//i.test(sourceUrl)) {
      try {
        const page = await fetchUrlPage(sourceUrl);
        imageUrl = imageUrl || page.image_url || "";
        imageSource = imageSource || page.image_source || "";
      } catch (_) {
        // Preview image is optional.
      }
    }
    const shouldSend = normalizeSendFlag(hooks.send, true);
    const hookPoints = formatLearnableTopics(hooks);
    const points = normalizePoints(
      meta.key_facts ||
        meta.upsc_points ||
        (hookPoints.length > 0 ? hookPoints : null) ||
        (meta.concept_to_test ? [meta.concept_to_test] : []),
    );
    const newsSummary =
      formatNewsSummary(hooks.news_summary) ||
      formatNewsSummary(hooks) ||
      formatNewsSummary(meta.news_summary) ||
      String(meta.news_summary || "").trim();
    const notificationTitle = shouldSend
      ? formatNotificationTitle(hooks).slice(0, MAX_TITLE)
      : "";
    const notificationBody = shouldSend
      ? formatNotificationBody(hooks).slice(0, MAX_BODY)
      : "";
    const headline = formatHeadline(hooks) || notificationTitle;
    const question = normalizeQuestion(q, sourceUrl);
    // Harvest may already have question.hi from Daily CA; still need summary HI.
    const hindi = await attachHindi({
      question,
      headline,
      newsSummary,
      upscPoints: points,
      sourceUrl,
      requestedModel,
    });
    return {
      ok: true,
      draft: {
        send: shouldSend,
        notification_title: notificationTitle,
        notification_body: notificationBody,
        headline,
        headline_hi: hindi.headline_hi,
        news_summary: newsSummary,
        news_summary_hi: hindi.news_summary_hi,
        source_url: sourceUrl,
        image_url: imageUrl,
        image_source: imageSource,
        upsc_points: points,
        upsc_points_hi: hindi.upsc_points_hi,
        question: hindi.question,
        harvest: { draft_date: draftDate, draft_id: draftId },
      },
    };
  }

  if (source === "url") {
    const url = String(data.url || "").trim();
    if (!url || !/^https?:\/\//i.test(url)) {
      throw new HttpsError("invalid-argument", "Valid http(s) URL required.");
    }
    try {
      const minClientText = 40;
      const maxClientText = 12000;
      const clientText = String(data.article_text || "").trim().slice(
        0,
        maxClientText,
      );
      let page = {
        text: "",
        image_url: String(data.image_url || "").trim(),
        image_source: String(data.image_source || "").trim(),
        og_title: "",
        og_description: "",
      };
      if (clientText.length >= minClientText) {
        page.text = clientText;
      } else {
        try {
          page = await fetchUrlPage(url);
        } catch (e) {
          throw new HttpsError(
            "failed-precondition",
            `Could not fetch URL: ${e.message || e}`,
          );
        }
      }
      const articleText = page.text || "";
      if (!articleText || articleText.length < minClientText) {
        throw new HttpsError(
          "failed-precondition",
          "URL returned too little text. Open the article in browser, share again, or use harvest.",
        );
      }
      const generated = await anthropicJson(
        loadPrompt("pulse_generate_system.txt"),
        JSON.stringify({ url, article_text: articleText.slice(0, 10000) }),
        requestedModel,
      );
      if (generated.error) {
        throw new HttpsError("failed-precondition", String(generated.error));
      }
      const questionRaw =
        generated.question && typeof generated.question === "object"
          ? generated.question
          : generated;
      const shouldSend = normalizeSendFlag(generated.send, true);
      const newsSummary =
        formatNewsSummary(generated.news_summary) ||
        formatNewsSummary(generated) ||
        String(generated.news_summary || "").trim();
      const generatedPoints = formatLearnableTopics(generated);
      const upscPoints =
        generatedPoints.length > 0
          ? generatedPoints
          : normalizePoints(generated.upsc_points);
      const question = normalizeQuestion(questionRaw, url);
      const notificationTitle = shouldSend
        ? formatNotificationTitle(generated).slice(0, MAX_TITLE)
        : "";
      const notificationBody = shouldSend
        ? formatNotificationBody(generated).slice(0, MAX_BODY)
        : "";
      const headline = formatHeadline(generated) || notificationTitle;
      const hindi = await attachHindi({
        question,
        headline,
        newsSummary,
        upscPoints,
        sourceUrl: url,
        requestedModel,
      });
      return {
        ok: true,
        draft: {
          send: shouldSend,
          notification_title: notificationTitle,
          notification_body: notificationBody,
          headline,
          headline_hi: hindi.headline_hi,
          news_summary: newsSummary,
          news_summary_hi: hindi.news_summary_hi,
          source_url: url,
          image_url: String(data.image_url || "").trim() || page.image_url || "",
          image_source:
            String(data.image_source || "").trim() || page.image_source || "",
          upsc_points: upscPoints,
          upsc_points_hi: hindi.upsc_points_hi,
          question: hindi.question,
          harvest: null,
        },
      };
    } catch (e) {
      console.error("generateFomoPulseDraft(url) failed:", e);
      throw toHttpsError(e);
    }
  }

  throw new HttpsError("invalid-argument", 'source must be "url" or "harvest".');
});

/**
 * Admin: Hindi for an already-generated Pulse MCQ. No Firestore write.
 * Prefer generate (auto-translates); this remains for re-translate.
 */
exports.translateFomoPulseDraft = onCall(generateOpts, async (request) => {
  requireAdmin(request);
  const data = request.data || {};
  const question = data.question;
  if (!question || typeof question !== "object") {
    throw new HttpsError("invalid-argument", "question required.");
  }
  const hindi = await attachHindi({
    question,
    headline: data.headline,
    newsSummary: data.news_summary,
    upscPoints: data.upsc_points,
    sourceUrl: data.source_url,
    force: true,
  });
  return {
    ok: true,
    question: hindi.question,
    headline_hi: hindi.headline_hi,
    news_summary_hi: hindi.news_summary_hi,
    upsc_points_hi: hindi.upsc_points_hi,
  };
});

/**
 * Admin: persist pulse + send FCM (self or broadcast).
 * Cost: 2 Firestore writes (pulse + notification analytics).
 * Auto-attaches Hindi if the draft is missing it (older clients / skipped translate).
 */
exports.sendFomoPulseNotification = onCall(generateOpts, async (request) => {
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

  const newsSummary = cleanNewsSummary(data.news_summary);
  let newsSummaryHi = cleanNewsSummary(data.news_summary_hi);
  const headline = textField(data.headline);
  let headlineHi = textField(data.headline_hi);
  let upscPoints = normalizePoints(data.upsc_points);
  let upscPointsHi = normalizePoints(data.upsc_points_hi);
  const sourceUrl = String(
    data.source_url || question.meta.source_url || "",
  ).trim();

  if (!hasQuestionHindi(question) || !newsSummaryHi || !headlineHi) {
    try {
      const hindi = await attachHindi({
        question,
        headline,
        newsSummary,
        upscPoints,
        sourceUrl,
        newsSummaryHi,
        upscPointsHi,
        headlineHi,
      });
      question = hindi.question;
      newsSummaryHi = hindi.news_summary_hi;
      upscPointsHi = hindi.upsc_points_hi;
      headlineHi = hindi.headline_hi || headlineHi;
    } catch (e) {
      console.error("sendFomoPulseNotification: Hindi attach failed:", e);
      // Still send English-only rather than blocking the push.
    }
  }

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
    headline,
    headline_hi: headlineHi,
    news_summary: newsSummary,
    news_summary_hi: newsSummaryHi,
    source_url: sourceUrl,
    image_url: String(data.image_url || "").trim(),
    image_source: String(data.image_source || "").trim(),
    upsc_points: upscPoints,
    upsc_points_hi: upscPointsHi,
    hindi_available: hasQuestionHindi(question),
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
 * Admin: hide a published CA Shot for everyone.
 * Soft-deletes (`status: deleted`) so the history query (`status == sent`)
 * and attempt callable both drop it. 1 Firestore read + 1 write.
 */
exports.deleteFomoPulse = onCall(
  { region: REGION, timeoutSeconds: 30, invoker: "public" },
  async (request) => {
    const email = requireAdmin(request);
    const pulseId = String((request.data || {}).pulse_id || "").trim();
    if (!pulseId) {
      throw new HttpsError("invalid-argument", "pulse_id required.");
    }
    const ref = db().collection(PULSES).doc(pulseId);
    const snap = await ref.get();
    if (!snap.exists) {
      throw new HttpsError("not-found", "Pulse not found.");
    }
    const status = String((snap.data() || {}).status || "");
    if (status === "deleted") {
      return { ok: true, pulseId, already_deleted: true };
    }
    await ref.update({
      status: "deleted",
      deleted_at: admin.firestore.FieldValue.serverTimestamp(),
      deleted_by: email,
    });
    return { ok: true, pulseId };
  },
);

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
