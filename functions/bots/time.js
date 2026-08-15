/** IST clock + Recents bucket path helpers (must match Flutter CommunityBucketUtils). */

const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

function istParts(utcDate = new Date()) {
  const shifted = new Date(utcDate.getTime() + IST_OFFSET_MS);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
    hour: shifted.getUTCHours(),
    minute: shifted.getUTCMinutes(),
    weekday: shifted.getUTCDay(),
    iso: formatIsoDate(shifted),
  };
}

function formatIsoDate(shifted) {
  const y = shifted.getUTCFullYear();
  const m = String(shifted.getUTCMonth() + 1).padStart(2, "0");
  const d = String(shifted.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** Unpadded `yyyy-m` / day, 3-hour bucket id — same as the Flutter Recents writer. */
function presenceBucketPath(utcDate = new Date()) {
  const p = istParts(utcDate);
  const hour = p.hour;
  let bucketId = "21";
  if (hour < 3) bucketId = "0";
  else if (hour < 6) bucketId = "3";
  else if (hour < 9) bucketId = "6";
  else if (hour < 12) bucketId = "9";
  else if (hour < 15) bucketId = "12";
  else if (hour < 18) bucketId = "15";
  else if (hour < 21) bucketId = "18";
  return {
    yearMonth: `${p.year}-${p.month}`,
    day: String(p.day),
    bucketId,
    parts: p,
  };
}

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

function hashString(s) {
  let h = 2166136261;
  const str = String(s);
  for (let i = 0; i < str.length; i++) {
    h ^= str.charCodeAt(i);
    h = Math.imul(h, 16777619);
  }
  return h >>> 0;
}

function mulberry32(seed) {
  let a = seed >>> 0;
  return function rand() {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function randInt(rng, min, max) {
  return min + Math.floor(rng() * (max - min + 1));
}

function pickN(list, n, rng) {
  const copy = [...list];
  for (let i = copy.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy.slice(0, Math.max(0, Math.min(n, copy.length)));
}

function pad2(n) {
  return String(n).padStart(2, "0");
}

/** Epoch ms for an IST civil datetime on `YYYY-MM-DD`. */
function istDateTimeMs(dateId, hour, minute) {
  return Date.parse(`${dateId}T${pad2(hour)}:${pad2(minute)}:00+05:30`);
}

function daysBetweenIso(fromId, toId) {
  const a = Date.parse(`${fromId}T00:00:00+05:30`);
  const b = Date.parse(`${toId}T00:00:00+05:30`);
  if (!Number.isFinite(a) || !Number.isFinite(b)) return 0;
  return Math.round((b - a) / (24 * 60 * 60 * 1000));
}

module.exports = {
  IST_OFFSET_MS,
  istParts,
  presenceBucketPath,
  sleep,
  hashString,
  mulberry32,
  randInt,
  pickN,
  istDateTimeMs,
  daysBetweenIso,
};
