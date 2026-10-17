/**
 * Prints how many published CA questions exist per month in
 * `daily_mcqs/{YYYY}/{MM}/{DD}`, so you can see how deep the archive is
 * before launching the test series.
 *
 * Usage (from the `functions` folder):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/count_ca_archive.js [fromYYYY-MM] [toYYYY-MM]
 *
 * Defaults: from 2025-01 to the current month.
 */
const admin = require("firebase-admin");
const { loadCaMonth, monthKey, shiftMonth } = require("../test_series/ca_pool");

function parseYm(text, fallback) {
  const m = /^(\d{4})-(\d{2})$/.exec(text || "");
  if (!m) return fallback;
  return [Number(m[1]), Number(m[2])];
}

async function main() {
  admin.initializeApp();
  const now = new Date();
  const [fy, fm] = parseYm(process.argv[2], [2025, 1]);
  const [ty, tm] = parseYm(process.argv[3], [
    now.getUTCFullYear(),
    now.getUTCMonth() + 1,
  ]);

  let [y, m] = [fy, fm];
  let total = 0;
  const rows = [];
  while (y < ty || (y === ty && m <= tm)) {
    const items = await loadCaMonth(y, m);
    const days = new Set(items.map((i) => i.date)).size;
    const bySubject = {};
    for (const it of items) {
      bySubject[it.gsSubject] = (bySubject[it.gsSubject] || 0) + 1;
    }
    rows.push({ month: monthKey(y, m), questions: items.length, days, bySubject });
    total += items.length;
    [y, m] = shiftMonth(y, m, 1);
  }

  for (const r of rows) {
    if (r.questions === 0) {
      console.log(`${r.month}  0 questions`);
      continue;
    }
    console.log(`${r.month}  ${r.questions} questions over ${r.days} days`);
    const subj = Object.entries(r.bySubject)
      .sort((a, b) => b[1] - a[1])
      .map(([k, v]) => `${k}:${v}`)
      .join(", ");
    console.log(`          ${subj}`);
  }
  console.log(`\nTotal CA questions: ${total}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
