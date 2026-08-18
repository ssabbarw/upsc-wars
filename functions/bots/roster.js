const admin = require("firebase-admin");
const crypto = require("crypto");
const {
  FIRST_NAMES,
  LAST_INITIALS,
  LAST_NAMES,
  OPTIONALS,
  PHONE_MODELS,
  APP_VERSION,
  RESERVED_BOT_EMAIL_DOMAIN,
  slugFirst,
  slugLast,
  needsReservedBotEmail,
  isConsumerEmail,
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

function emailsOf(bot) {
  const set = new Set();
  const current = String(bot.email || "").toLowerCase();
  if (current) set.add(current);
  const prev = Array.isArray(bot.previousEmails) ? bot.previousEmails : [];
  for (const e of prev) {
    const n = String(e || "").toLowerCase();
    if (n) set.add(n);
  }
  return set;
}

function collectBotEmails(roster) {
  const set = new Set();
  for (const b of roster) {
    for (const e of emailsOf(b)) set.add(e);
  }
  return set;
}

function allocatePublicUid() {
  const chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
  const bytes = crypto.randomBytes(28);
  let out = "";
  for (let i = 0; i < 28; i++) out += chars[bytes[i] % chars.length];
  return out;
}

function buildPublicEmail(firstName, lastName, lastInitial, n) {
  const first = slugFirst(firstName);
  const last = slugLast(lastName) || String(lastInitial || "k").toLowerCase();
  return `${first}.${last}${n}@${RESERVED_BOT_EMAIL_DOMAIN}`;
}

function usedEmails(roster) {
  return collectBotEmails(roster);
}

function buildBotIdentity(roster, seed) {
  const rng = mulberry32(hashString(seed));
  const taken = usedNames(roster);
  const emails = usedEmails(roster);
  const takenDisplay = usedDisplayNames(roster);
  const takenUids = new Set(
    roster.map((b) => String(b.publicUid || "")).filter(Boolean),
  );
  for (let i = 0; i < 400; i++) {
    const firstName = FIRST_NAMES[Math.floor(rng() * FIRST_NAMES.length)];
    const lastInitial = LAST_INITIALS[Math.floor(rng() * LAST_INITIALS.length)];
    const key = `${firstName}|${lastInitial}`;
    if (taken.has(key)) continue;
    const n = randInt(rng, 11, 98);
    const picked = pickDisplayName(firstName, rng, takenDisplay);
    if (takenDisplay.has(picked.name.toLowerCase())) continue;
    const email = buildPublicEmail(firstName, picked.lastName, lastInitial, n);
    if (emails.has(email)) continue;
    const optional = OPTIONALS[Math.floor(rng() * OPTIONALS.length)];
    const phoneModel = PHONE_MODELS[Math.floor(rng() * PHONE_MODELS.length)];
    const skill = 0.38 + rng() * 0.28;
    const id = `bot_${slugFirst(firstName)}_${lastInitial.toLowerCase()}${n}`;
    let publicUid = allocatePublicUid();
    while (takenUids.has(publicUid)) publicUid = allocatePublicUid();
    return {
      id,
      publicUid,
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
  return roster.find((b) => emailsOf(b).has(want)) || null;
}

function warUidFor(bot) {
  return String(bot.publicUid || "").trim() || bot.id;
}

async function rewriteEmailInRecentBuckets(oldEmail, newEmail, bot) {
  if (!oldEmail || !newEmail || oldEmail === newEmail) return;
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
    const entry = (snap.data() || {})[oldEmail];
    if (!entry) continue;
    const next = {
      ...(typeof entry === "object" && entry ? entry : {}),
      email: newEmail,
      name: bot.name,
    };
    await ref.set(
      {
        [newEmail]: next,
        [oldEmail]: admin.firestore.FieldValue.delete(),
      },
      { merge: true },
    );
  }
}

/** Drop a bot mailbox only when it does not look like a real signed-in user. */
async function releaseOldUserDoc(oldEmail) {
  const ref = db().collection("users").doc(oldEmail);
  const snap = await ref.get();
  if (!snap.exists) return;
  const data = snap.data() || {};
  const hasToken = Boolean(data.fcm_token || data.fcmToken);
  const hasInsta = Boolean(data.insta_user_id || data.insta);
  if (hasToken || hasInsta) {
    console.warn("bots.releaseOldUserDoc: skip delete, looks like a real user", {
      email: oldEmail,
      consumer: isConsumerEmail(oldEmail),
    });
    return;
  }
  await ref.delete();
}

async function ensurePublicIdentities(roster) {
  const takenEmails = collectBotEmails(roster);
  const takenUids = new Set(
    roster.map((b) => String(b.publicUid || "")).filter(Boolean),
  );
  let updated = 0;
  for (const b of roster) {
    const currentEmail = String(b.email || "").toLowerCase();
    const needsEmail = !currentEmail || needsReservedBotEmail(currentEmail);
    const needsUid = !String(b.publicUid || "").trim();
    if (!needsEmail && !needsUid) {
      if (currentEmail) {
        const userRef = db().collection("users").doc(currentEmail);
        const userSnap = await userRef.get();
        if (userSnap.exists && userSnap.data().isBot === true) {
          await userRef.set(
            { isBot: admin.firestore.FieldValue.delete() },
            { merge: true },
          );
        }
      }
      continue;
    }

    const patch = {};
    if (needsUid) {
      let publicUid = allocatePublicUid();
      while (takenUids.has(publicUid)) publicUid = allocatePublicUid();
      b.publicUid = publicUid;
      takenUids.add(publicUid);
      patch.publicUid = publicUid;
    }
    if (needsEmail) {
      const rng = mulberry32(hashString(`publicemail:${b.id}`));
      let next = null;
      for (let i = 0; i < 80; i++) {
        const n = randInt(rng, 11, 98);
        const candidate = buildPublicEmail(
          b.firstName || b.name,
          b.lastName,
          b.lastInitial,
          n + i,
        );
        if (takenEmails.has(candidate)) continue;
        const existing = await db().collection("users").doc(candidate).get();
        if (existing.exists) continue;
        next = candidate;
        break;
      }
      if (!next) {
        next = `${slugFirst(b.firstName || "warrior")}.${allocatePublicUid().slice(0, 8).toLowerCase()}@${RESERVED_BOT_EMAIL_DOMAIN}`;
      }
      const previous = [...emailsOf(b)];
      if (currentEmail && currentEmail !== next) {
        b.previousEmails = [...new Set([...(b.previousEmails || []), currentEmail])];
        patch.previousEmails = b.previousEmails;
      }
      b.email = next;
      takenEmails.add(next);
      patch.email = next;
      await writeUserDoc(b);
      for (const oldEmail of previous) {
        if (oldEmail === next) continue;
        await releaseOldUserDoc(oldEmail);
        await rewriteEmailInRecentBuckets(oldEmail, next, b);
      }
    } else {
      await writeUserDoc(b);
    }
    await rosterCol().doc(b.id).set(patch, { merge: true });
    updated += 1;
  }
  return updated;
}

async function publishTrafficBotIndex(roster) {
  const emails = [...collectBotEmails(roster)];
  const uids = [];
  for (const b of roster) {
    if (b.publicUid) uids.push(String(b.publicUid));
    if (b.id) uids.push(String(b.id));
  }
  await db()
    .collection("admin_dashboard")
    .doc("traffic_bots")
    .set(
      {
        emails,
        uids: [...new Set(uids)],
        updatedAtMs: Date.now(),
      },
      { merge: true },
    );
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
  ensurePublicIdentities,
  publishTrafficBotIndex,
  writeUserDoc,
  usersDoc,
  dayStats,
  canBattleUser,
  claimBotForBattle,
  releaseBotBattle,
  getBotByEmail,
  getBot,
  emailsOf,
  collectBotEmails,
  warUidFor,
  rosterCol,
};
