/**
 * Read-only helpers over the published daily CA archive
 * (`daily_mcqs/{YYYY}/{MM}/{DD}`), shared by the monthly test-series function
 * and the one-off archive depth script.
 *
 * A "CA pool item" is the lightweight shape the test builder needs:
 *   { uuid, gsSubject, date, month, poolOrder }
 * Full question content is never copied; the app fetches the day documents.
 */
const admin = require("firebase-admin");
const crypto = require("crypto");

const LIVE = "daily_mcqs";
const URL_NS = Buffer.from("6ba7b8119dad11d180b400c04fd430c8", "hex");

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

/** Same formula as the daily CA publisher and the Flutter upsert. */
function currentAffairsQuestionUuid(sourceDate, poolOrder) {
  return uuidV5(`upsc-wars|ca|${sourceDate}|${poolOrder}`);
}

function pad2(n) {
  return String(n).padStart(2, "0");
}

function daysInMonth(year, month) {
  return new Date(Date.UTC(year, month, 0)).getUTCDate();
}

function monthKey(year, month) {
  return `${year}-${pad2(month)}`;
}

/** Returns [year, month] shifted by `delta` months (delta may be negative). */
function shiftMonth(year, month, delta) {
  const idx = year * 12 + (month - 1) + delta;
  return [Math.floor(idx / 12), (idx % 12) + 1];
}

function questionList(raw) {
  if (Array.isArray(raw)) return raw;
  if (raw && typeof raw === "object") {
    return Object.keys(raw)
      .sort((a, b) => Number(a) - Number(b))
      .map((k) => raw[k]);
  }
  return [];
}

/** Loads one published day. Returns [] when the day has no document. */
async function loadCaDay(iso) {
  const [y, m, d] = iso.split("-");
  const snap = await admin
    .firestore()
    .collection(LIVE)
    .doc(y)
    .collection(m)
    .doc(d)
    .get();
  if (!snap.exists) return [];
  const data = snap.data() || {};
  const items = [];
  questionList(data.questions).forEach((q, index) => {
    if (!q || typeof q !== "object") return;
    const meta = q.meta && typeof q.meta === "object" ? q.meta : {};
    const poolOrder =
      Number.isFinite(Number(meta.pool_order)) && meta.pool_order !== ""
        ? Number(meta.pool_order)
        : index;
    const uuid =
      typeof q.uuid === "string" && q.uuid
        ? q.uuid
        : currentAffairsQuestionUuid(iso, poolOrder);
    items.push({
      uuid,
      gsSubject: String(meta.gs_subject || q.gs_subject || "Current affairs"),
      date: iso,
      month: `${y}-${m}`,
      poolOrder,
    });
  });
  return items;
}

/** Loads every published question for a calendar month. */
async function loadCaMonth(year, month) {
  const last = daysInMonth(year, month);
  const dayIsos = [];
  for (let d = 1; d <= last; d += 1) {
    dayIsos.push(`${year}-${pad2(month)}-${pad2(d)}`);
  }
  const perDay = await Promise.all(dayIsos.map((iso) => loadCaDay(iso)));
  return perDay.flat();
}

module.exports = {
  currentAffairsQuestionUuid,
  daysInMonth,
  loadCaDay,
  loadCaMonth,
  monthKey,
  shiftMonth,
};
