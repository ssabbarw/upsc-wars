/**
 * Publishes every due `pending_ca` test (monthly CA tests and mock tests)
 * from your machine - the same logic the scheduled function runs daily.
 * Run it once right after uploading the series so the launch-day tests are live.
 *
 * Usage (from the `functions` folder):
 *   GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json \
 *     node scripts/publish_test_series_due.js [seriesId] [--dry-run] [--as-of=2026-10-17T10:00:00Z]
 */
const admin = require("firebase-admin");
const { publishAllDue, publishDueTests } = require("../test_series/builder");

async function main() {
  const args = process.argv.slice(2);
  const seriesId = args.find((a) => !a.startsWith("--"));
  const dryRun = args.includes("--dry-run");
  const asOfArg = args.find((a) => a.startsWith("--as-of="));
  const asOf = asOfArg ? new Date(asOfArg.split("=")[1]) : new Date();
  if (Number.isNaN(asOf.getTime())) throw new Error("Invalid --as-of");

  admin.initializeApp();
  const results = seriesId
    ? { [seriesId]: await publishDueTests(seriesId, asOf, { dryRun }) }
    : await publishAllDue(asOf, { dryRun });
  console.log(JSON.stringify(results, null, 2));
}

main().catch((e) => {
  console.error(e);
  process.exit(1);
});
