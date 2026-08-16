const admin = require("firebase-admin");
const {
  FIRST_NAMES,
  LAST_INITIALS,
  LAST_NAMES,
  OPTIONALS,
  PHONE_MODELS,
  APP_VERSION,
  BOT_EMAIL_DOMAIN,
  slugFirst,
} = require("./names");
const { hashString, mulberry32, randInt, presenceBucketPath } = require("./time");

function db() {
  return admin.firestore();
}

function rosterCol() {
  return db().collection("bot_roster");
}

async function listRoster() {
  const snap = await rosterCol().get();
  return snap.docs.map((d) => ({ id: d.id, ...d.data() }));
}

function activeBots(roster) {
  return roster.filter((b) => b.status === "active");
}

function usedDisplayNames(roster) {
  return new Set(
    roster
      .map((b) => String(b.name || "").trim().toLowerCase())
      .filter(Boolean),
  );
}

function isInitialStyleName(name) {
  return /^\S+\s[A-Z]$/.test(String(name || "").trim());
}

function pickDisplayName(firstName, rng, takenDisplay) {
  const wantFirstOnly = rng() < 0.55;
  const firstKey = firstName.toLowerCase();
  if (wantFirstOnly && !takenDisplay.has(firstKey)) {
    return { name: firstName, lastName: null };
  }
  for (let i = 0; i < 80; i++) {
    const lastName = LAST_NAMES[Math.floor(rng() * LAST_NAMES.length)];
    const full = `${firstName} ${lastName}`;
    if (!takenDisplay.has(full.toLowerCase())) {
      return { name: full, lastName };
    }
  }
  if (!takenDisplay.has(firstKey)) {
    return { name: firstName, lastName: null };
  }
  const lastName = LAST_NAMES[Math.floor(rng() * LAST_NAMES.length)];
  return { name: `${firstName} ${lastName}`, lastName };
}

function usedNames(roster) {
  return new Set(roster.map((b) => `${b.firstName}|${b.lastInitial}`));
}

function usedEmails(roster) {
  return new Set(roster.map((b) => String(b.email || "").toLowerCase()));
}

function buildBotIdentity(roster, seed) {
  const rng = mulberry32(hashString(seed));
  const taken = usedNames(roster);
  const emails = usedEmails(roster);
  const takenDisplay = usedDisplayNames(roster);
  for (let i = 0; i < 400; i++) {
    const firstName = FIRST_NAMES[Math.floor(rng() * FIRST_NAMES.length)];
    const lastInitial = LAST_INITIALS[Math.floor(rng() * LAST_INITIALS.length)];
    const key = `${firstName}|${lastInitial}`;
    if (taken.has(key)) continue;
    const n = randInt(rng, 11, 98);
    const email = `${slugFirst(firstName)}.${lastInitial.toLowerCase()}${n}@${BOT_EMAIL_DOMAIN}`;
    if (emails.has(email)) continue;
    const picked = pickDisplayName(firstName, rng, takenDisplay);
    if (takenDisplay.has(picked.name.toLowerCase())) continue;
    const optional = OPTIONALS[Math.floor(rng() * OPTIONALS.length)];
    const phoneModel = PHONE_MODELS[Math.floor(rng() * PHONE_MODELS.length)];
    const skill = 0.38 + rng() * 0.28;
    const id = `bot_${slugFirst(firstName)}_${lastInitial.toLowerCase()}${n}`;
    return {
      id,
      email,
      firstName,
      lastInitial,
      lastName: picked.lastName,
      name: picked.name,
      optional: optional || null,
      phoneModel,
      appVersion: APP_VERSION,
      skill: Number(skill.toFixed(2)),
      status: "active",
      acceptingBattleInvites: true,
      createdAtMs: Date.now(),
    };
  }
  throw new Error("Could not allocate a unique bot identity");
}

async function ensureFriendlyNames(roster) {
  const taken = new Set();
  for (const b of roster) {
    const n = String(b.name || "").trim();
    if (n && !isInitialStyleName(n)) taken.add(n.toLowerCase());
  }
  let updated = 0;
  for (const b of roster) {
    if (!isInitialStyleName(b.name)) continue;
    const rng = mulberry32(hashString(`displayname:${b.id}`));
    const first = b.firstName || String(b.name).split(/\s+/)[0];
    const picked = pickDisplayName(first, rng, taken);
    taken.add(picked.name.toLowerCase());
    b.name = picked.name;
    b.lastName = picked.lastName;
    b.firstName = first;
    await rosterCol()
      .doc(b.id)
      .set(
        {
          name: picked.name,
          lastName: picked.lastName,
          firstName: first,
        },
        { merge: true },
      );
    await writeUserDoc(b);
    await patchBotNameInRecentBuckets(b.email, picked.name);
    updated += 1;
  }
  return updated;
}

async function patchBotNameInRecentBuckets(email, name) {
  if (!email || !name) return;
  const seen = new Set();
  for (let i = 0; i < 12; i++) {
    const path = presenceBucketPath(new Date(Date.now() - i * 3 * 60 * 60 * 1000));
    const key = `${path.yearMonth}/${path.day}/${path.bucketId}`;
    if (seen.has(key)) continue;
    seen.add(key);
    const ref = db()
      .collection("buckets")
      .doc(path.yearMonth)
      .collection(path.day)
      .doc(path.bucketId);
    const snap = await ref.get();
    if (!snap.exists) continue;
    const entry = (snap.data() || {})[email];
    if (!entry) continue;
    await ref.set({ [email]: { ...entry, name } }, { merge: true });
  }
}

function usersDoc(bot, extra = {}) {
  const payload = {
    email: bot.email,
    name: bot.name,
    photoURL: null,
    acceptingBattleInvites: bot.acceptingBattleInvites !== false,
    lastOnlineTime: extra.lastOnlineTime || 0,
    isBot: true,
    appVersion: bot.appVersion || APP_VERSION,
    phoneModel: bot.phoneModel || null,
  };
  if (bot.optional) payload.optional = bot.optional;
  if (extra.isInBattle != null) payload.isInBattle = extra.isInBattle;
  return payload;
}

async function writeUserDoc(bot, extra = {}) {
  await db()
    .collection("users")
    .doc(bot.email)
    .set(usersDoc(bot, extra), { merge: true });
}

async function createBot(roster, seed) {
  const bot = buildBotIdentity(roster, seed);
  await rosterCol().doc(bot.id).set(bot);
  await writeUserDoc(bot, { lastOnlineTime: 0 });
  roster.push(bot);
  return bot;
}

async function restBot(bot) {
  await rosterCol().doc(bot.id).set(
    {
      status: "resting",
      restedAtMs: Date.now(),
      appearDateId: admin.firestore.FieldValue.delete(),
      firstAppearAtMs: admin.firestore.FieldValue.delete(),
      isNewToday: false,
      acceptingBattleInvites: false,
      inBattleSessionId: admin.firestore.FieldValue.delete(),
    },
    { merge: true },
  );
  bot.status = "resting";
}

async function retireBot(bot) {
  await rosterCol().doc(bot.id).set(
    {
      status: "retired",
      retiredAtMs: Date.now(),
      inBattleSessionId: admin.firestore.FieldValue.delete(),
      acceptingBattleInvites: false,
    },
    { merge: true },
  );
  await db()
    .collection("users")
    .doc(bot.email)
    .set(
      {
        acceptingBattleInvites: false,
        lastOnlineTime: Date.now() - 26 * 60 * 60 * 1000,
        isInBattle: Date.now() - 60 * 60 * 1000,
      },
      { merge: true },
    );
  bot.status = "retired";
  try {
    const path = presenceBucketPath();
    await db()
      .collection("buckets")
      .doc(path.yearMonth)
      .collection(path.day)
      .doc(path.bucketId)
      .update(
        new admin.firestore.FieldPath(bot.email),
        admin.firestore.FieldValue.delete(),
      );
  } catch (_) {
    // Presence bucket may not exist.
  }
}

function dayStats(bot, dateId) {
  const stats = bot.dayStats && typeof bot.dayStats === "object" ? bot.dayStats : {};
  if (stats.dateId !== dateId) {
    return {
      dateId,
      battles: 0,
      acceptedFrom: [],
      invited: [],
    };
  }
  return {
    dateId,
    battles: Number(stats.battles) || 0,
    acceptedFrom: Array.isArray(stats.acceptedFrom) ? stats.acceptedFrom : [],
    invited: Array.isArray(stats.invited) ? stats.invited : [],
  };
}

function opponentDate(bot, email) {
  const map = bot.recentOpponents && typeof bot.recentOpponents === "object"
    ? bot.recentOpponents
    : {};
  return map[String(email || "").toLowerCase()] || null;
}

function isoMinusDays(dateId, days) {
  const [y, m, d] = dateId.split("-").map((n) => Number(n));
  const dt = new Date(Date.UTC(y, m - 1, d));
  dt.setUTCDate(dt.getUTCDate() - days);
  const yy = dt.getUTCFullYear();
  const mm = String(dt.getUTCMonth() + 1).padStart(2, "0");
  const dd = String(dt.getUTCDate()).padStart(2, "0");
  return `${yy}-${mm}-${dd}`;
}

function canBattleUser(bot, humanEmail, dateId, cfg) {
  const email = String(humanEmail || "").toLowerCase();
  const stats = dayStats(bot, dateId);
  if (stats.battles >= cfg.battlesPerDayMax) return false;
  if (stats.acceptedFrom.includes(email) || stats.invited.includes(email)) {
    return false;
  }
  const last = opponentDate(bot, email);
  if (last && last > isoMinusDays(dateId, cfg.sameUserCooldownDays)) {
    return false;
  }
  if (bot.inBattleSessionId) return false;
  return true;
}

async function claimBotForBattle(botId, sessionId, humanEmail, dateId, cfg, kind) {
  const ref = rosterCol().doc(botId);
  return db().runTransaction(async (tx) => {
    const snap = await tx.get(ref);
    if (!snap.exists) return { ok: false, reason: "missing" };
    const bot = { id: snap.id, ...snap.data() };
    if (bot.status !== "active") return { ok: false, reason: "retired" };
    if (!canBattleUser(bot, humanEmail, dateId, cfg)) {
      return { ok: false, reason: "busy_or_capped" };
    }
    const stats = dayStats(bot, dateId);
    stats.battles += 1;
    const email = String(humanEmail || "").toLowerCase();
    if (kind === "outgoing") stats.invited.push(email);
    else stats.acceptedFrom.push(email);
    const recent = Object.assign({}, bot.recentOpponents || {});
    recent[email] = dateId;
    tx.update(ref, {
      dayStats: stats,
      recentOpponents: recent,
      inBattleSessionId: sessionId,
      inBattleUntilMs: Date.now() + 15 * 60 * 1000,
    });
    return { ok: true, bot: { ...bot, dayStats: stats, inBattleSessionId: sessionId } };
  });
}

async function releaseBotBattle(botId) {
  await rosterCol().doc(botId).set(
    {
      inBattleSessionId: admin.firestore.FieldValue.delete(),
      inBattleUntilMs: admin.firestore.FieldValue.delete(),
    },
    { merge: true },
  );
}

async function getBotByEmail(email) {
  const want = String(email || "").toLowerCase();
  if (!want) return null;
  const roster = await listRoster();
  return roster.find((b) => String(b.email || "").toLowerCase() === want) || null;
}

async function getBot(botId) {
  const snap = await rosterCol().doc(botId).get();
  if (!snap.exists) return null;
  return { id: snap.id, ...snap.data() };
}

function surfacedToday(roster, dateId, now = Date.now()) {
  return roster.filter((b) => {
    if (b.status !== "active") return false;
    if (b.appearDateId !== dateId) return false;
    return Number(b.firstAppearAtMs || 0) <= now;
  });
}

function isBotLiveToday(bot, dateId, now = Date.now()) {
  if (!bot || bot.status !== "active") return false;
  if (bot.appearDateId !== dateId) return false;
  return Number(bot.firstAppearAtMs || 0) <= now;
}

module.exports = {
  listRoster,
  activeBots,
  surfacedToday,
  isBotLiveToday,
  createBot,
  restBot,
  ensureFriendlyNames,
  writeUserDoc,
  usersDoc,
  dayStats,
  canBattleUser,
  claimBotForBattle,
  releaseBotBattle,
  getBotByEmail,
  getBot,
  rosterCol,
};
