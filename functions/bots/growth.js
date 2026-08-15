const admin = require("firebase-admin");
const crypto = require("crypto");
const {
  istParts,
  hashString,
  mulberry32,
  randInt,
  pickN,
  istDateTimeMs,
  daysBetweenIso,
} = require("./time");
const { nextDailyTarget } = require("./config");
const {
  listRoster,
  createBot,
  restBot,
  rosterCol,
} = require("./roster");

function db() {
  return admin.firestore();
}

function metaRef() {
  return db().collection("bot_state").doc("meta");
}

function byId(roster) {
  const map = new Map();
  for (const b of roster) map.set(b.id, b);
  return map;
}

/** Spread first-seen times so Recents does not get a clump of new names. */
function spreadFirstAppearMs(count, dateId, rng) {
  const parts = istParts();
  const now = Date.now();
  const dayStart = istDateTimeMs(dateId, 7, 20);
  const dayEnd = istDateTimeMs(dateId, 22, 40);
  const start = Math.max(now + 4 * 60 * 1000, dayStart);
  const end = Math.max(start + 20 * 60 * 1000, dayEnd);
  const window = Math.max(end - start, 15 * 60 * 1000);
  const minGap = Math.min(12 * 60 * 1000, Math.floor(window / Math.max(count, 1)));
  const times = [];
  for (let i = 0; i < count; i++) {
    const even = start + Math.floor((window * (i + 0.5)) / Math.max(count, 1));
    const jitter = randInt(rng, -Math.floor(minGap / 2), Math.floor(minGap / 2));
    times.push(Math.min(end, Math.max(start, even + jitter)));
  }
  times.sort((a, b) => a - b);
  for (let i = 1; i < times.length; i++) {
    if (times[i] < times[i - 1] + Math.min(minGap, 6 * 60 * 1000)) {
      times[i] = times[i - 1] + Math.min(minGap, 6 * 60 * 1000);
    }
  }
  return times;
}

function returningEligible(roster, dateId) {
  return roster.filter((b) => {
    if (b.status !== "resting") return false;
    const last = b.lastAppearDateId || b.appearDateId;
    if (!last) return true;
    return daysBetweenIso(last, dateId) >= 2;
  });
}

async function markAppearing(bot, dateId, firstAppearAtMs, isNewToday) {
  await rosterCol()
    .doc(bot.id)
    .set(
      {
        status: "active",
        appearDateId: dateId,
        firstAppearAtMs,
        isNewToday: Boolean(isNewToday),
        lastAppearDateId: dateId,
        acceptingBattleInvites: true,
      },
      { merge: true },
    );
  bot.status = "active";
  bot.appearDateId = dateId;
  bot.firstAppearAtMs = firstAppearAtMs;
  bot.isNewToday = Boolean(isNewToday);
}

/**
 * Once per IST day: grow the visible set (5, 8, +3/day, cap 100),
 * drop 15–30% of yesterday, add the rest as new/returning faces,
 * and stagger first-seen times across waking hours.
 */
async function planToday(cfg) {
  const dateId = istParts().iso;
  const snap = await metaRef().get();
  const meta = snap.data() || {};
  if (meta.plannedDateId === dateId && Array.isArray(meta.todayAppearIds)) {
    return {
      skipped: "already_planned",
      dateId,
      dayIndex: meta.dayIndex,
      target: meta.targetAppear,
      appear: (meta.todayAppearIds || []).length,
    };
  }

  const roster = await listRoster();
  const launchDateId = meta.launchDateId || dateId;
  const dayIndex = daysBetweenIso(launchDateId, dateId) + 1;
  const yesterdayIds = Array.isArray(meta.todayAppearIds)
    ? meta.todayAppearIds
    : [];
  const target = nextDailyTarget(cfg, dayIndex, yesterdayIds.length);
  const retracting = target < yesterdayIds.length;
  const rng = mulberry32(hashString(`plan:${dateId}`));

  let droppedIds = [];
  let keepIds = [];
  let dropRate = null;
  if (retracting) {
    // Wind down: keep a smaller slice of yesterday. No new names.
    keepIds = pickN(yesterdayIds, target, rng);
    const keepSet = new Set(keepIds);
    droppedIds = yesterdayIds.filter((id) => !keepSet.has(id));
  } else {
    dropRate =
      cfg.dailyDropMin + rng() * (cfg.dailyDropMax - cfg.dailyDropMin);
    const dropCount = Math.min(
      yesterdayIds.length,
      Math.round(yesterdayIds.length * dropRate),
    );
    const shuffledY = pickN(yesterdayIds, yesterdayIds.length, rng);
    droppedIds = shuffledY.slice(0, dropCount);
    keepIds = shuffledY.slice(dropCount);
    if (keepIds.length > target) {
      const extra = keepIds.length - target;
      droppedIds = droppedIds.concat(keepIds.slice(0, extra));
      keepIds = keepIds.slice(extra);
    }
  }
  const droppedSet = new Set(droppedIds);

  const need = retracting ? 0 : Math.max(0, target - keepIds.length);
  const returningPool = returningEligible(roster, dateId).filter(
    (b) => !keepIds.includes(b.id) && !droppedSet.has(b.id),
  );
  const returnCount = Math.min(
    returningPool.length,
    Math.floor(need * (0.25 + rng() * 0.15)),
  );
  const returning = pickN(returningPool, returnCount, rng);
  let created = [];
  const stillNeed = need - returning.length;
  for (let i = 0; i < stillNeed; i++) {
    const bot = await createBot(roster, `grow:${dateId}:${i}:${crypto.randomUUID()}`);
    created.push(bot);
  }

  const newcomers = [...returning, ...created];
  const newTimes = spreadFirstAppearMs(newcomers.length, dateId, rng);
  const keepTimes = spreadFirstAppearMs(keepIds.length, dateId, rng);
  // Returning faces can show from morning; brand-new faces use the staggered slots.
  const map = byId(roster);

  for (let i = 0; i < keepIds.length; i++) {
    const bot = map.get(keepIds[i]);
    if (!bot) continue;
    const morning = istDateTimeMs(dateId, randInt(rng, 6, 10), randInt(rng, 0, 50));
    const first = Math.max(Date.now() + 60 * 1000, Math.min(morning, keepTimes[i] || morning));
    await markAppearing(bot, dateId, first, false);
  }

  const newIds = [];
  for (let i = 0; i < newcomers.length; i++) {
    const bot = newcomers[i];
    const isBrandNew = created.some((c) => c.id === bot.id);
    await markAppearing(bot, dateId, newTimes[i], isBrandNew);
    newIds.push(bot.id);
  }

  for (const id of droppedIds) {
    const bot = map.get(id);
    if (bot && !bot.inBattleSessionId) {
      await restBot(bot);
    }
  }

  const todayAppearIds = [...keepIds, ...newIds];
  await metaRef().set(
    {
      launchDateId,
      plannedDateId: dateId,
      dayIndex,
      targetAppear: target,
      retracting,
      appearPerDayTarget: cfg.appearPerDayTarget,
      dropRate: dropRate == null ? null : Number(dropRate.toFixed(3)),
      yesterdayAppearIds: yesterdayIds,
      todayAppearIds,
      todayNewIds: newIds,
      todayDroppedIds: droppedIds,
      todayCreatedIds: created.map((b) => b.id),
      todayReturningIds: returning.map((b) => b.id),
      plannedAtMs: Date.now(),
    },
    { merge: true },
  );

  return {
    dateId,
    dayIndex,
    target,
    retracting,
    keep: keepIds.length,
    dropped: droppedIds.length,
    created: created.length,
    returning: returning.length,
    appear: todayAppearIds.length,
  };
}

module.exports = { planToday, spreadFirstAppearMs };
