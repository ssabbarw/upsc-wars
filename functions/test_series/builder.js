/**
 * Fills the current-affairs part of test-series tests once their unlock date
 * has passed:
 *
 *  - `ca` tests: a month-window mix (about 30 from the previous month, the
 *    rest from the two months before it).
 *  - `flt` mocks: the CA slots (about 35 of 100) drawn from the whole archive
 *    published before the unlock date, favouring the last two months.
 *
 * Both are shuffled together with the PYQs already in the test. A question is
 * never reused across the series' CA tests / mocks. Each CA entry stores its
 * `date` (needed to fetch the question) and `sourceMonth`; the app never shows
 * either to the user.
 */
const admin = require("firebase-admin");
const crypto = require("crypto");
const { loadCaMonth, monthKey, shiftMonth } = require("./ca_pool");

const MIN_CA_QUESTIONS = 20; // do not publish a CA test below this
const MINUTES_PER_QUESTION = 1.2;

// ---- seeded RNG (deterministic per test so re-runs give the same paper) ----

function seedFrom(text) {
  const h = crypto.createHash("sha256").update(text).digest();
  return h.readUInt32LE(0);
}

function mulberry32(seed) {
  let a = seed >>> 0;
  return function next() {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function shuffle(arr, rand) {
  const a = arr.slice();
  for (let i = a.length - 1; i > 0; i -= 1) {
    const j = Math.floor(rand() * (i + 1));
    [a[i], a[j]] = [a[j], a[i]];
  }
  return a;
}

/** Weighted sample without replacement (Efraimidis-Spirakis). */
function weightedSample(items, weightOf, n, rand) {
  return items
    .map((it) => ({ it, k: Math.pow(rand(), 1 / Math.max(weightOf(it), 1e-6)) }))
    .sort((a, b) => b.k - a.k)
    .slice(0, n)
    .map((x) => x.it);
}

function durationMins(count) {
  return Math.round((count * MINUTES_PER_QUESTION) / 5) * 5;
}

// ---- helpers ---------------------------------------------------------------

function toEntry(item) {
  return {
    uuid: item.uuid,
    kind: "ca",
    date: item.date,
    sourceMonth: item.month,
  };
}

function parseMonth(key) {
  const [y, m] = String(key).split("-").map(Number);
  return [y, m];
}

/** CA uuids already used by published CA tests / mocks of the series. */
async function usedCaUuids(testsRef) {
  const snap = await testsRef.get();
  const used = new Set();
  snap.forEach((doc) => {
    const d = doc.data() || {};
    if (d.status !== "ready") return;
    for (const q of d.questions || []) {
      if (q && q.kind === "ca") used.add(q.uuid);
    }
  });
  return used;
}

async function loadMonths(keys, cache) {
  const out = {};
  for (const key of keys) {
    if (!cache.has(key)) {
      const [y, m] = parseMonth(key);
      cache.set(key, await loadCaMonth(y, m));
    }
    out[key] = cache.get(key);
  }
  return out;
}

// ---- builders --------------------------------------------------------------

function pickForCaTest(test, byMonth, used, rand) {
  const want = test.caSlots || 45;
  const primaryWant = test.caPrimarySlots || Math.round(want * 0.65);
  const win = test.caWindow || {};
  const primary = shuffle(
    (byMonth[win.primaryMonth] || []).filter((q) => !used.has(q.uuid)),
    rand,
  );
  const earlier = shuffle(
    (win.earlierMonths || [])
      .flatMap((k) => byMonth[k] || [])
      .filter((q) => !used.has(q.uuid)),
    rand,
  );

  const picked = [];
  picked.push(...primary.slice(0, primaryWant));
  const primaryLeft = primary.slice(primaryWant);
  const needFromEarlier = want - picked.length;
  picked.push(...earlier.slice(0, needFromEarlier));
  // The archive may not reach back 3 months yet: top up from the primary month.
  if (picked.length < want) {
    picked.push(...primaryLeft.slice(0, want - picked.length));
  }
  return picked;
}

const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;

/** `YYYY-MM-DD` of an instant in IST. */
function istIso(date) {
  return new Date(date.getTime() + IST_OFFSET_MS).toISOString().slice(0, 10);
}

function pickForFlt(test, byMonth, used, rand, unlockIso) {
  const want = test.caSlots || 35;
  const monthsDesc = Object.keys(byMonth).sort().reverse();
  const recent = new Set(monthsDesc.slice(0, 2));
  const pool = Object.entries(byMonth)
    .flatMap(([, items]) => items)
    .filter((q) => !used.has(q.uuid) && q.date < unlockIso);
  return weightedSample(pool, (q) => (recent.has(q.month) ? 2 : 1), want, rand);
}

/**
 * Publishes every due `pending_ca` test of one series.
 * @returns {Promise<Array<object>>} per-test result summaries.
 */
async function publishDueTests(seriesId, now = new Date(), { dryRun = false } = {}) {
  const db = admin.firestore();
  const testsRef = db.collection("test_series").doc(seriesId).collection("tests");
  // Single-field query (no composite index); the date filter is done here.
  const pendingSnap = await testsRef.where("status", "==", "pending_ca").get();
  const nowMs = now.getTime();
  const due = pendingSnap.docs
    .map((d) => ({ ref: d.ref, id: d.id, data: d.data() }))
    .filter((t) => t.data.unlockAt && t.data.unlockAt.toMillis() <= nowMs)
    .sort((a, b) => a.data.unlockAt.toMillis() - b.data.unlockAt.toMillis());
  if (due.length === 0) return [];

  const used = await usedCaUuids(testsRef);
  const monthCache = new Map();
  const results = [];

  for (const t of due) {
    const test = t.data;
    const rand = mulberry32(seedFrom(`${seriesId}|${t.id}`));
    const unlockIsoDate = istIso(test.unlockAt.toDate());
    let picked = [];

    if (test.kind === "ca") {
      const win = test.caWindow || {};
      const keys = [win.primaryMonth, ...(win.earlierMonths || [])].filter(Boolean);
      const byMonth = await loadMonths(keys, monthCache);
      picked = pickForCaTest(test, byMonth, used, rand);
    } else if (test.kind === "flt") {
      const [uy, um] = unlockIsoDate.split("-").map(Number);
      const keys = [];
      for (let back = 0; back <= 9; back += 1) {
        const [y, m] = shiftMonth(uy, um, -back);
        keys.push(monthKey(y, m));
      }
      const byMonth = await loadMonths(keys, monthCache);
      picked = pickForFlt(test, byMonth, used, rand, unlockIsoDate);
    } else {
      results.push({ id: t.id, status: "skipped", reason: `unsupported kind ${test.kind}` });
      continue;
    }

    if (picked.length < MIN_CA_QUESTIONS) {
      results.push({
        id: t.id,
        status: "waiting",
        reason: `only ${picked.length} CA questions available`,
      });
      continue;
    }

    const merged = shuffle(
      [...(test.questions || []), ...picked.map(toEntry)],
      rand,
    );
    for (const p of picked) used.add(p.uuid);

    const update = {
      questions: merged,
      questionCount: merged.length,
      durationMins: durationMins(merged.length),
      status: "ready",
      caFilledAt: admin.firestore.FieldValue.serverTimestamp(),
    };
    if (!dryRun) await t.ref.update(update);
    results.push({
      id: t.id,
      status: dryRun ? "dry-run" : "published",
      caQuestions: picked.length,
      total: merged.length,
    });
  }
  return results;
}

/** Publishes due tests for every series. */
async function publishAllDue(now = new Date(), opts = {}) {
  const series = await admin.firestore().collection("test_series").get();
  const all = {};
  for (const doc of series.docs) {
    all[doc.id] = await publishDueTests(doc.id, now, opts);
  }
  return all;
}

module.exports = { publishDueTests, publishAllDue, MIN_CA_QUESTIONS };
