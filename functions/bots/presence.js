const admin = require("firebase-admin");
const { presenceBucketPath, hashString, mulberry32, randInt } = require("./time");
const { surfacedToday, writeUserDoc } = require("./roster");
const { APP_VERSION } = require("./names");

function db() {
  return admin.firestore();
}

function pickOnlineBots(bots, dateId, hour, count) {
  if (!bots.length || count <= 0) return [];
  const ranked = [...bots].sort((a, b) => {
    const ha = hashString(`slot:${dateId}:${hour}:${a.id}`);
    const hb = hashString(`slot:${dateId}:${hour}:${b.id}`);
    return ha - hb;
  });
  return ranked.slice(0, Math.min(count, ranked.length));
}

function bucketPayload(bot, lastOnlineTime, isInBattle) {
  return {
    name: bot.name,
    optional: bot.optional || null,
    email: bot.email,
    telegram: null,
    insta: null,
    photoURL: null,
    my_status: null,
    isInBattle: isInBattle || null,
    phoneModel: bot.phoneModel || null,
    appVersion: bot.appVersion || APP_VERSION,
    lastOnlineTime,
    acceptingBattleInvites: true,
  };
}

async function upsertPresence(bot, lastOnlineTime, isInBattle) {
  const path = presenceBucketPath();
  const ref = db()
    .collection("buckets")
    .doc(path.yearMonth)
    .collection(path.day)
    .doc(path.bucketId);
  await ref.set(
    { [bot.email]: bucketPayload(bot, lastOnlineTime, isInBattle) },
    { merge: true },
  );
  await writeUserDoc(bot, { lastOnlineTime, isInBattle });
}

async function dropFromCurrentBucket(email) {
  const path = presenceBucketPath();
  const ref = db()
    .collection("buckets")
    .doc(path.yearMonth)
    .collection(path.day)
    .doc(path.bucketId);
  try {
    await ref.update(
      new admin.firestore.FieldPath(email),
      admin.firestore.FieldValue.delete(),
    );
  } catch (_) {
    // Bucket doc may not exist yet.
  }
}

async function tickPresence(cfg, roster) {
  const path = presenceBucketPath();
  const dateId = path.parts.iso;
  const eligible = surfacedToday(roster, dateId);
  const rng = mulberry32(hashString(`online:${dateId}:${path.parts.hour}`));
  const frac =
    cfg.onlineFractionMin + rng() * (cfg.onlineFractionMax - cfg.onlineFractionMin);
  let n = Math.round(eligible.length * frac);
  if (eligible.length > 0) n = Math.max(1, n);
  n = Math.min(n, eligible.length, cfg.onlinePerHourCap);
  const online = pickOnlineBots(eligible, dateId, path.parts.hour, n);
  const now = Date.now();
  const jitterRng = mulberry32(
    hashString(`jitter:${dateId}:${path.parts.hour}:${Math.floor(now / 60000)}`),
  );

  for (const bot of online) {
    const lastOnlineTime = now - randInt(jitterRng, 20 * 1000, 8 * 60 * 1000);
    const inBattle =
      bot.inBattleUntilMs && bot.inBattleUntilMs > now
        ? bot.inBattleUntilMs
        : null;
    await upsertPresence(bot, lastOnlineTime, inBattle);
  }

  await db().collection("bot_state").doc("meta").set(
    {
      lastPresenceAtMs: now,
      lastOnlineBotIds: online.map((b) => b.id),
      lastOnlineHour: path.parts.hour,
      lastEligibleCount: eligible.length,
    },
    { merge: true },
  );

  return {
    online: online.length,
    eligible: eligible.length,
    hour: path.parts.hour,
    dateId,
  };
}

module.exports = {
  pickOnlineBots,
  tickPresence,
  upsertPresence,
  dropFromCurrentBucket,
};
