/**
 * Uploads the JSON produced by `tools/test_series/generate_series.py` to
 * Firestore (`test_series/{seriesId}` and `test_series/{seriesId}/tests/{id}`).
 *
 * Safe to re-run: tests that already exist are SKIPPED (so published current
 * affairs / mock tests are never overwritten) unless you pass --force.
 *
 * Usage (from the `functions` folder):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/upload_test_series.js ../tools/test_series/out/prelims_2027.json [--dry-run] [--force]
 */
const fs = require("fs");
const path = require("path");
const admin = require("firebase-admin");

const TIMESTAMP_FIELDS = ["unlockAt", "launchAt"];

function toTimestamps(obj) {
  const out = { ...obj };
  for (const f of TIMESTAMP_FIELDS) {
    if (typeof out[f] === "string") {
      out[f] = admin.firestore.Timestamp.fromDate(new Date(out[f]));
    }
  }
  return out;
}

async function main() {
  const args = process.argv.slice(2);
  const file = args.find((a) => !a.startsWith("--"));
  const dryRun = args.includes("--dry-run");
  const force = args.includes("--force");
  if (!file) {
    console.error("Usage: node scripts/upload_test_series.js <series.json> [--dry-run] [--force]");
    process.exit(1);
  }
  const payload = JSON.parse(fs.readFileSync(path.resolve(file), "utf8"));
  const { series, tests } = payload;
  if (!series || !series.id || !Array.isArray(tests)) {
    throw new Error("Invalid series file.");
  }

  admin.initializeApp();
  const db = admin.firestore();
  const seriesRef = db.collection("test_series").doc(series.id);
  const testsRef = seriesRef.collection("tests");

  console.log(`Series ${series.id}: ${tests.length} tests (dryRun=${dryRun}, force=${force})`);

  if (!dryRun) {
    await seriesRef.set(
      { ...toTimestamps(series), updatedAt: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
  }

  let written = 0;
  let skipped = 0;
  let batch = db.batch();
  let inBatch = 0;
  for (const t of tests) {
    const ref = testsRef.doc(t.id);
    const existing = await ref.get();
    if (existing.exists && !force) {
      skipped += 1;
      continue;
    }
    written += 1;
    if (dryRun) continue;
    batch.set(ref, {
      ...toTimestamps(t),
      seriesId: series.id,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    inBatch += 1;
    if (inBatch >= 200) {
      await batch.commit();
      batch = db.batch();
      inBatch = 0;
    }
  }
  if (!dryRun && inBatch > 0) await batch.commit();

  console.log(`Done. written=${written} skipped(existing)=${skipped}`);
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
