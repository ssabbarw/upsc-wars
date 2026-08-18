/**
 * Admin LLM config for Daily CA vs CA Shots.
 *
 * Keys live in Firestore `admin_secrets/llm` (Admin SDK only).
 * Fallback: process.env.ANTHROPIC_API_KEY_CA / ANTHROPIC_API_KEY_SHOTS /
 * ANTHROPIC_API_KEY so existing deploys keep working.
 */

const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");

const REGION = "asia-south1";
const SECRETS_COL = "admin_secrets";
const SECRETS_DOC = "llm";

const HAIKU = "claude-haiku-4-5-20251001";
const SONNET = "claude-sonnet-4-6";
const SONNET_5 = "claude-sonnet-5";
const OPUS = "claude-opus-4-6";
const OPUS_5 = "claude-opus-5";
const FABLE = "claude-fable-5";

const ALLOWED_MODELS = [
  { id: HAIKU, label: "Haiku 4.5", blurb: "Fast and cheap. Weaker traps." },
  { id: SONNET, label: "Sonnet 4.6", blurb: "Recommended default for Shots." },
  { id: SONNET_5, label: "Sonnet 5", blurb: "Latest balanced. Stronger than 4.6." },
  { id: OPUS, label: "Opus 4.6", blurb: "Stronger reasoning. Slower." },
  { id: OPUS_5, label: "Opus 5", blurb: "Latest strong. Slow and pricey." },
  { id: FABLE, label: "Fable 5", blurb: "Frontier. Slowest and ~3× Opus cost." },
];

const ALLOWED_IDS = new Set(ALLOWED_MODELS.map((m) => m.id));

const DEFAULT_SHOTS_MODEL = SONNET;
const DEFAULT_CA_MODEL = SONNET;

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

let _cache = { at: 0, value: null };
const CACHE_MS = 15_000;

function requireAdmin(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const email = (request.auth.token.email || "").trim().toLowerCase();
  if (!ADMIN_EMAILS.has(email)) {
    throw new HttpsError("permission-denied", "Admin only.");
  }
  return email;
}

function db() {
  return admin.firestore();
}

function secretsRef() {
  return db().collection(SECRETS_COL).doc(SECRETS_DOC);
}

function normalizeModel(raw, fallback) {
  const id = String(raw || "").trim();
  return ALLOWED_IDS.has(id) ? id : fallback;
}

function hintForKey(key) {
  const k = String(key || "").trim();
  if (!k) return "";
  if (k.length <= 8) return "••••";
  return `${k.slice(0, 7)}…${k.slice(-4)}`;
}

function envKey(...names) {
  for (const name of names) {
    const v = String(process.env[name] || "").trim();
    if (v) return v;
  }
  return "";
}

async function readStored() {
  const snap = await secretsRef().get();
  return snap.exists ? snap.data() || {} : {};
}

async function loadLlmConfig() {
  const now = Date.now();
  if (_cache.value && now - _cache.at < CACHE_MS) return _cache.value;
  const stored = await readStored();
  const value = {
    shotsModel: normalizeModel(stored.shots_model, DEFAULT_SHOTS_MODEL),
    caModel: normalizeModel(stored.ca_model, DEFAULT_CA_MODEL),
    shotsApiKey:
      String(stored.shots_api_key || "").trim() ||
      envKey("ANTHROPIC_API_KEY_SHOTS", "ANTHROPIC_API_KEY"),
    caApiKey:
      String(stored.ca_api_key || "").trim() ||
      envKey("ANTHROPIC_API_KEY_CA", "ANTHROPIC_API_KEY"),
    shotsKeyStored: Boolean(String(stored.shots_api_key || "").trim()),
    caKeyStored: Boolean(String(stored.ca_api_key || "").trim()),
  };
  _cache = { at: now, value };
  return value;
}

function invalidateLlmConfigCache() {
  _cache = { at: 0, value: null };
}

function requireKey(key, label) {
  if (!key) {
    throw new HttpsError(
      "failed-precondition",
      `${label} API key is not set. Add it in Settings → LLM & API keys.`,
    );
  }
  return key;
}

function maxTokensFor(model) {
  return String(model).includes("haiku") ? 4096 : 8192;
}

function validateIncomingKey(raw) {
  const key = String(raw || "").trim();
  if (!key) return "";
  if (key.length < 20) {
    throw new HttpsError("invalid-argument", "API key looks too short.");
  }
  return key;
}

async function anthropicJson({
  system,
  userContent,
  model,
  apiKey,
  maxTokens,
}) {
  const key = requireKey(apiKey, "Anthropic");
  const resolvedModel = normalizeModel(model, DEFAULT_SHOTS_MODEL);
  const res = await fetch("https://api.anthropic.com/v1/messages", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "x-api-key": key,
      "anthropic-version": "2023-06-01",
    },
    body: JSON.stringify({
      model: resolvedModel,
      max_tokens: maxTokens || maxTokensFor(resolvedModel),
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
  return { text, model: resolvedModel };
}

const callableOpts = {
  region: REGION,
  timeoutSeconds: 30,
  memory: "256MiB",
};

exports.getLlmAdminSettings = onCall(callableOpts, async (request) => {
  requireAdmin(request);
  const cfg = await loadLlmConfig();
  return {
    ok: true,
    models: ALLOWED_MODELS,
    shots_model: cfg.shotsModel,
    ca_model: cfg.caModel,
    shots_key_set: Boolean(cfg.shotsApiKey),
    ca_key_set: Boolean(cfg.caApiKey),
    shots_key_hint: cfg.shotsKeyStored ? hintForKey(cfg.shotsApiKey) : "",
    ca_key_hint: cfg.caKeyStored ? hintForKey(cfg.caApiKey) : "",
    shots_key_from_env: Boolean(cfg.shotsApiKey) && !cfg.shotsKeyStored,
    ca_key_from_env: Boolean(cfg.caApiKey) && !cfg.caKeyStored,
  };
});

exports.setLlmAdminSettings = onCall(callableOpts, async (request) => {
  const email = requireAdmin(request);
  const data = request.data || {};
  const stored = await readStored();
  const patch = {
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_by: email,
  };

  if (data.shots_model != null) {
    patch.shots_model = normalizeModel(data.shots_model, DEFAULT_SHOTS_MODEL);
  }
  if (data.ca_model != null) {
    patch.ca_model = normalizeModel(data.ca_model, DEFAULT_CA_MODEL);
  }

  if (data.clear_shots_key === true) {
    patch.shots_api_key = "";
  } else if (data.shots_api_key != null && String(data.shots_api_key).trim()) {
    patch.shots_api_key = validateIncomingKey(data.shots_api_key);
  }

  if (data.clear_ca_key === true) {
    patch.ca_api_key = "";
  } else if (data.ca_api_key != null && String(data.ca_api_key).trim()) {
    patch.ca_api_key = validateIncomingKey(data.ca_api_key);
  }

  await secretsRef().set(patch, { merge: true });
  invalidateLlmConfigCache();
  return { ok: true };
});

exports.loadLlmConfig = loadLlmConfig;
exports.normalizeModel = normalizeModel;
exports.anthropicJson = anthropicJson;
exports.requireKey = requireKey;
exports.maxTokensFor = maxTokensFor;
exports.DEFAULT_SHOTS_MODEL = DEFAULT_SHOTS_MODEL;
exports.DEFAULT_CA_MODEL = DEFAULT_CA_MODEL;
exports.ALLOWED_MODELS = ALLOWED_MODELS;
