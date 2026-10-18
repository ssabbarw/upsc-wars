/**
 * Cloud Functions for the paid Prelims Test Series.
 *
 *  - publishTestSeriesDue (scheduled, daily 06:00 IST): fills the current
 *    affairs part of every test whose unlock date has passed. On the 1st of
 *    each month this publishes the new monthly CA test; mid-month it
 *    publishes any mock test that unlocks that day. 06:00 leaves time for the
 *    midnight daily-CA auto-publish to finish for the previous day.
 *  - adminPublishTestSeriesDue (callable, admin only): same, on demand.
 *  - Promo codes and "free for everyone" offers: see ./promos.js.
 */
const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const { publishAllDue, publishDueTests } = require("./builder");
const promos = require("./promos");

const REGION = "asia-south1";

exports.publishTestSeriesDue = onSchedule(
  {
    schedule: "0 6 * * *",
    timeZone: "Asia/Kolkata",
    region: REGION,
    timeoutSeconds: 540,
    memory: "512MiB",
  },
  async () => {
    const results = await publishAllDue(new Date());
    console.log("publishTestSeriesDue", JSON.stringify(results));
    return results;
  },
);

exports.adminPublishTestSeriesDue = onCall(
  { region: REGION, timeoutSeconds: 540, memory: "512MiB" },
  async (request) => {
    // Lazy require avoids a circular import at cold start.
    require("../daily_ca")._requireAdmin(request);
    const data = request.data || {};
    const seriesId = typeof data.seriesId === "string" ? data.seriesId.trim() : "";
    const dryRun = data.dryRun === true;
    const asOf = data.asOf ? new Date(String(data.asOf)) : new Date();
    if (Number.isNaN(asOf.getTime())) {
      throw new HttpsError("invalid-argument", "asOf must be an ISO date.");
    }
    if (seriesId) {
      return { [seriesId]: await publishDueTests(seriesId, asOf, { dryRun }) };
    }
    return publishAllDue(asOf, { dryRun });
  },
);

exports.redeemTestSeriesCode = promos.redeemTestSeriesCode;
exports.adminCreateTestSeriesPromo = promos.adminCreateTestSeriesPromo;
exports.adminSetTestSeriesPromoActive = promos.adminSetTestSeriesPromoActive;
