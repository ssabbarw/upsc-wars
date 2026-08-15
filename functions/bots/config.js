const admin = require("firebase-admin");

const DEFAULTS = {
  enabled: true,
  day1Count: 5,
  day2Count: 8,
  growthPerDay: 3,
  appearPerDayMax: 100,
  appearPerDayTarget: 100,
  retractPerDay: 8,
  dailyDropMin: 0.15,
  dailyDropMax: 0.3,
  onlineFractionMin: 0.12,
  onlineFractionMax: 0.2,
  onlinePerHourCap: 12,
  tickMinutes: 5,
  battlesPerDayMax: 3,
  acceptRate: 0.55,
  outgoingInvitesPerDay: 3,
  qotdPerDay: 1,
  openChallengeEveryNDays: 4,
  dailyWarFraction: 0.4,
  sameUserCooldownDays: 2,
};

function parseBool(raw, fallback) {
  if (raw === undefined || raw === null || raw === "") return fallback;
  if (raw === true || raw === "true" || raw === "1") return true;
  if (raw === false || raw === "false" || raw === "0") return false;
  return fallback;
}

function parseNumber(raw, fallback) {
  if (raw === undefined || raw === null || raw === "") return fallback;
  const n = Number(raw);
  return Number.isFinite(n) ? n : fallback;
}

function rcValue(params, key) {
  const p = params[key];
  if (!p || !p.defaultValue) return undefined;
  return p.defaultValue.value;
}

function clamp(n, lo, hi) {
  return Math.max(lo, Math.min(hi, n));
}

async function readBotConfig() {
  let params = {};
  try {
    const template = await admin.remoteConfig().getTemplate();
    params = template.parameters || {};
  } catch (e) {
    console.warn("readBotConfig: remote config failed, using defaults", e);
  }

  const dropMin = clamp(
    parseNumber(rcValue(params, "bots_daily_drop_min"), DEFAULTS.dailyDropMin),
    0,
    0.9,
  );
  const dropMax = Math.max(
    dropMin,
    clamp(
      parseNumber(rcValue(params, "bots_daily_drop_max"), DEFAULTS.dailyDropMax),
      0,
      0.9,
    ),
  );
  const fracMin = clamp(
    parseNumber(rcValue(params, "bots_online_fraction_min"), DEFAULTS.onlineFractionMin),
    0,
    1,
  );
  const fracMax = Math.max(
    fracMin,
    clamp(
      parseNumber(rcValue(params, "bots_online_fraction_max"), DEFAULTS.onlineFractionMax),
      0,
      1,
    ),
  );

  return {
    enabled: parseBool(rcValue(params, "bots_enabled"), DEFAULTS.enabled),
    day1Count: Math.max(
      1,
      Math.floor(parseNumber(rcValue(params, "bots_day1_count"), DEFAULTS.day1Count)),
    ),
    day2Count: Math.max(
      1,
      Math.floor(parseNumber(rcValue(params, "bots_day2_count"), DEFAULTS.day2Count)),
    ),
    growthPerDay: Math.max(
      0,
      Math.floor(parseNumber(rcValue(params, "bots_growth_per_day"), DEFAULTS.growthPerDay)),
    ),
    appearPerDayMax: Math.max(
      1,
      Math.min(
        100,
        Math.floor(
          parseNumber(rcValue(params, "bots_appear_per_day_max"), DEFAULTS.appearPerDayMax),
        ),
      ),
    ),
    appearPerDayTarget: Math.max(
      0,
      Math.min(
        100,
        Math.floor(
          parseNumber(
            rcValue(params, "bots_appear_per_day_target"),
            DEFAULTS.appearPerDayTarget,
          ),
        ),
      ),
    ),
    retractPerDay: Math.max(
      1,
      Math.min(
        40,
        Math.floor(
          parseNumber(rcValue(params, "bots_retract_per_day"), DEFAULTS.retractPerDay),
        ),
      ),
    ),
    dailyDropMin: dropMin,
    dailyDropMax: dropMax,
    onlineFractionMin: fracMin,
    onlineFractionMax: fracMax,
    onlinePerHourCap: Math.max(
      1,
      Math.min(
        30,
        Math.floor(
          parseNumber(rcValue(params, "bots_online_per_hour_cap"), DEFAULTS.onlinePerHourCap),
        ),
      ),
    ),
    tickMinutes: Math.max(
      1,
      Math.min(60, Math.floor(parseNumber(rcValue(params, "bots_tick_minutes"), DEFAULTS.tickMinutes))),
    ),
    battlesPerDayMax: Math.max(
      1,
      Math.min(8, Math.floor(parseNumber(rcValue(params, "bots_battles_per_day_max"), DEFAULTS.battlesPerDayMax))),
    ),
    acceptRate: Math.max(
      0,
      Math.min(1, parseNumber(rcValue(params, "bots_accept_rate"), DEFAULTS.acceptRate)),
    ),
    outgoingInvitesPerDay: Math.max(
      0,
      Math.min(20, Math.floor(parseNumber(rcValue(params, "bots_outgoing_invites_per_day"), DEFAULTS.outgoingInvitesPerDay))),
    ),
    qotdPerDay: Math.max(
      0,
      Math.min(5, Math.floor(parseNumber(rcValue(params, "bots_qotd_per_day"), DEFAULTS.qotdPerDay))),
    ),
    openChallengeEveryNDays: Math.max(
      1,
      Math.min(14, Math.floor(parseNumber(rcValue(params, "bots_open_challenge_every_n_days"), DEFAULTS.openChallengeEveryNDays))),
    ),
    dailyWarFraction: Math.max(
      0,
      Math.min(1, parseNumber(rcValue(params, "bots_daily_war_fraction"), DEFAULTS.dailyWarFraction)),
    ),
    sameUserCooldownDays: Math.max(
      0,
      Math.min(14, Math.floor(parseNumber(rcValue(params, "bots_same_user_cooldown_days"), DEFAULTS.sameUserCooldownDays))),
    ),
  };
}

/** Unique bots that should show up in Recents over this IST day (growth ceiling). */
function targetAppearCount(dayIndex, cfg) {
  const d = Math.max(1, Math.floor(Number(dayIndex) || 1));
  if (d <= 1) return Math.min(cfg.appearPerDayMax, cfg.day1Count);
  if (d === 2) return Math.min(cfg.appearPerDayMax, cfg.day2Count);
  return Math.min(
    cfg.appearPerDayMax,
    cfg.day2Count + (d - 2) * cfg.growthPerDay,
  );
}

/**
 * Move yesterday's unique count one step toward the operator target.
 * Retract at most `retractPerDay`; grow at most the organic schedule.
 */
function nextDailyTarget(cfg, dayIndex, yesterdayCount) {
  const growthCeiling = targetAppearCount(dayIndex, cfg);
  const goal = Math.min(growthCeiling, Math.max(0, Number(cfg.appearPerDayTarget) || 0));
  const yesterday = Math.max(0, Number(yesterdayCount) || 0);

  if (yesterday <= 0) {
    return Math.min(goal, cfg.day1Count);
  }
  if (goal < yesterday) {
    return Math.max(goal, yesterday - Math.max(1, cfg.retractPerDay));
  }
  if (goal > yesterday) {
    const maxRise =
      dayIndex <= 2
        ? Math.max(cfg.growthPerDay, cfg.day2Count - cfg.day1Count)
        : cfg.growthPerDay;
    return Math.min(goal, yesterday + Math.max(0, maxRise));
  }
  return goal;
}

module.exports = { DEFAULTS, readBotConfig, targetAppearCount, nextDailyTarget };
