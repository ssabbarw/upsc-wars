/**
 * Daily War Cloud Functions — paper generate / publish / submit / rank.
 *
 * Firestore:
 *   daily_wars/{YYYY-MM-DD}
 *   daily_wars/{dateId}/private/answers
 *   daily_wars/{dateId}/submissions/{uid}
 *   daily_wars/{dateId}/meta/leaderboard
 *   daily_war_state/curriculum
 */

const { onSchedule } = require("firebase-functions/v2/scheduler");
const { onCall, HttpsError } = require("firebase-functions/v2/https");
const admin = require("firebase-admin");
const fs = require("fs");
const path = require("path");

const IST_OFFSET_MS = (5 * 60 + 30) * 60 * 1000;
const WARS = "daily_wars";
const STATE = "daily_war_state";
const CURRICULUM_DOC = "curriculum";
/** RTDB path for cheap lobby / writing social counts (polled by clients). */
const RTDB_COUNTS = "daily_war_counts";

/** Matches client DailyWarSchedule.secondsPerQuestion. */
const SECONDS_PER_QUESTION = 80;
const WEEKDAY_QUESTION_COUNT = 15;

function liveWindowMinutesFor(questionCount) {
  const q =
    Number(questionCount) > 0 ? Number(questionCount) : WEEKDAY_QUESTION_COUNT;
  return Math.min(120, Math.max(1, Math.ceil((q * SECONDS_PER_QUESTION) / 60)));
}

function liveEndMsFor(dateId, questionCount) {
  const startMs = Date.parse(`${dateId}T21:00:00+05:30`);
  return startMs + liveWindowMinutesFor(questionCount) * 60 * 1000;
}

function rtdbCountsRef(dateId) {
  return admin.database().ref(`${RTDB_COUNTS}/${dateId}`);
}

/** Increment a count field without touching the Firestore war doc (avoids listener fan-out). */
async function bumpLiveCount(dateId, field) {
  await rtdbCountsRef(dateId)
    .child(field)
    .set(admin.database.ServerValue.increment(1));
}

async function readLiveCount(dateId, field) {
  const snap = await rtdbCountsRef(dateId).child(field).get();
  const v = snap.val();
  return typeof v === "number" ? v : 0;
}

const SUBJECT_ROTATION = [
  "polity",
  "economy",
  "modern_history",
  "geography",
  "environment",
  "ancient_history",
  "art_and_culture",
  "medieval_history",
];

/** Mirrors lib/features/daily_war/domain/daily_war_curriculum.dart */
const TOPICS_BY_SUBJECT = require("./curriculum_topics.json");

let _questionIndex = null;
function questionIndex() {
  if (_questionIndex) return _questionIndex;
  const p = path.join(__dirname, "question_index.json");
  _questionIndex = JSON.parse(fs.readFileSync(p, "utf8"));
  return _questionIndex;
}

function db() {
  return admin.firestore();
}

function nowIst(date = new Date()) {
  return new Date(date.getTime() + IST_OFFSET_MS);
}

function formatIsoDate(ist) {
  const y = ist.getUTCFullYear();
  const m = String(ist.getUTCMonth() + 1).padStart(2, "0");
  const d = String(ist.getUTCDate()).padStart(2, "0");
  return `${y}-${m}-${d}`;
}

/** IST calendar parts from a UTC Date via offset trick on a shifted Date. */
function istParts(utcDate = new Date()) {
  const shifted = new Date(utcDate.getTime() + IST_OFFSET_MS);
  return {
    year: shifted.getUTCFullYear(),
    month: shifted.getUTCMonth() + 1,
    day: shifted.getUTCDate(),
    hour: shifted.getUTCHours(),
    minute: shifted.getUTCMinutes(),
    weekday: shifted.getUTCDay(), // 0=Sun
    iso: formatIsoDate(shifted),
  };
}

function isSunday(parts) {
  return parts.weekday === 0;
}

function shuffleInPlace(arr) {
  for (let i = arr.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1));
    [arr[i], arr[j]] = [arr[j], arr[i]];
  }
  return arr;
}

function pickTopicsForSubject(subjectSlug, topicIndex) {
  const list = TOPICS_BY_SUBJECT[subjectSlug] || [];
  if (!list.length) return { topics: [], nextIndex: 0 };
  const topics = [];
  let idx = ((topicIndex % list.length) + list.length) % list.length;
  for (let i = 0; i < 2; i++) {
    topics.push({ subject: subjectSlug, topic: list[idx] });
    idx = (idx + 1) % list.length;
  }
  return { topics, nextIndex: idx };
}

function poolForTopics(topics) {
  const index = questionIndex();
  const pool = [];
  for (const t of topics) {
    const key = `${t.subject}::${t.topic}`;
    const rows = index[key] || [];
    for (const r of rows) {
      pool.push({ uuid: r.u, correct: r.c, subTopic: r.st || "", topic: t.topic, subject: t.subject });
    }
  }
  return pool;
}

/**
 * Prefer balanced subtopics: round-robin across sub_topic buckets.
 */
function selectQuestions(pool, count) {
  if (pool.length <= count) {
    return shuffleInPlace(pool.slice()).slice(0, pool.length);
  }
  const bySt = new Map();
  for (const q of pool) {
    const k = q.subTopic || "_";
    if (!bySt.has(k)) bySt.set(k, []);
    bySt.get(k).push(q);
  }
  for (const arr of bySt.values()) shuffleInPlace(arr);

  const keys = shuffleInPlace([...bySt.keys()]);
  const picked = [];
  const used = new Set();
  let guard = 0;
  while (picked.length < count && guard < count * 20) {
    guard++;
    for (const k of keys) {
      if (picked.length >= count) break;
      const arr = bySt.get(k);
      while (arr.length) {
        const q = arr.pop();
        if (used.has(q.uuid)) continue;
        used.add(q.uuid);
        picked.push(q);
        break;
      }
    }
  }
  return picked;
}

async function loadCurriculum() {
  const ref = db().collection(STATE).doc(CURRICULUM_DOC);
  const snap = await ref.get();
  const data = snap.exists ? snap.data() : {};
  return {
    ref,
    subjectRotationIndex: data.subject_rotation_index || 0,
    topicIndexBySubject: data.topic_index_by_subject || {},
  };
}

async function pickWeekdayTopics(curriculum) {
  const subject =
    SUBJECT_ROTATION[
      curriculum.subjectRotationIndex % SUBJECT_ROTATION.length
    ];
  const topicIndex = curriculum.topicIndexBySubject[subject] || 0;
  const { topics, nextIndex } = pickTopicsForSubject(subject, topicIndex);
  return {
    topics,
    kind: "daily",
    questionCount: 15,
    patch: {
      subject_rotation_index:
        (curriculum.subjectRotationIndex + 1) % SUBJECT_ROTATION.length,
      topic_index_by_subject: {
        ...curriculum.topicIndexBySubject,
        [subject]: nextIndex,
      },
    },
  };
}

async function pickGrandTopics(curriculum, dateId) {
  // Prefer topics from the last 6 weekday wars (revision of the week).
  const topics = [];
  const seen = new Set();
  const [y, m, d] = dateId.split("-").map(Number);
  for (let i = 1; i <= 6; i++) {
    const dt = new Date(Date.UTC(y, m - 1, d - i));
    const iso = `${dt.getUTCFullYear()}-${String(dt.getUTCMonth() + 1).padStart(2, "0")}-${String(dt.getUTCDate()).padStart(2, "0")}`;
    const snap = await db().collection(WARS).doc(iso).get();
    if (!snap.exists) continue;
    const tlist = snap.data().topics || [];
    for (const t of tlist) {
      const key = `${t.subject}::${t.topic}`;
      if (seen.has(key)) continue;
      seen.add(key);
      topics.push({ subject: t.subject, topic: t.topic });
    }
  }
  if (topics.length >= 2) {
    return {
      topics,
      kind: "grand",
      questionCount: 25,
      patch: null,
    };
  }
  const weekday = await pickWeekdayTopics(curriculum);
  return { ...weekday, kind: "grand", questionCount: 25 };
}

async function peekNextTopics(curriculum, afterPatch) {
  const nextCurriculum = {
    subjectRotationIndex:
      (afterPatch && afterPatch.subject_rotation_index != null
        ? afterPatch.subject_rotation_index
        : curriculum.subjectRotationIndex) % SUBJECT_ROTATION.length,
    topicIndexBySubject:
      (afterPatch && afterPatch.topic_index_by_subject) ||
      curriculum.topicIndexBySubject,
  };
  const subject =
    SUBJECT_ROTATION[
      nextCurriculum.subjectRotationIndex % SUBJECT_ROTATION.length
    ];
  const topicIndex = nextCurriculum.topicIndexBySubject[subject] || 0;
  const { topics } = pickTopicsForSubject(subject, topicIndex);
  return topics;
}

async function generateWarForDateId(dateId, { force = false } = {}) {
  const warRef = db().collection(WARS).doc(dateId);
  const existing = await warRef.get();
  if (existing.exists && !force) {
    return { ok: true, skipped: true, dateId };
  }

  const curriculum = await loadCurriculum();
  const noonUtc = new Date(`${dateId}T06:30:00.000Z`); // 12:00 IST
  const isGrand = istParts(noonUtc).weekday === 0;

  const picked = isGrand
    ? await pickGrandTopics(curriculum, dateId)
    : await pickWeekdayTopics(curriculum);

  const pool = poolForTopics(picked.topics);
  const selected = selectQuestions(pool, picked.questionCount);
  if (selected.length < Math.min(10, picked.questionCount)) {
    throw new Error(
      `Insufficient questions for ${dateId}: got ${selected.length}`,
    );
  }

  const nextTopics = await peekNextTopics(curriculum, picked.patch);

  const publicDoc = {
    date_id: dateId,
    kind: picked.kind,
    topics: picked.topics,
    next_topics: nextTopics,
    question_count: selected.length,
    status: "announced",
    question_uuids: [],
    participant_count: 0,
    lobby_count: 0,
    created_at: admin.firestore.FieldValue.serverTimestamp(),
    updated_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  const answersDoc = {
    answers: Object.fromEntries(selected.map((q) => [q.uuid, q.correct])),
    uuids: selected.map((q) => q.uuid),
    created_at: admin.firestore.FieldValue.serverTimestamp(),
  };

  const batch = db().batch();
  batch.set(warRef, publicDoc, { merge: true });
  batch.set(warRef.collection("private").doc("answers"), answersDoc);
  if (picked.patch) {
    batch.set(
      curriculum.ref,
      {
        ...picked.patch,
        last_date_id: dateId,
        updated_at: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true },
    );
  }
  await batch.commit();
  return { ok: true, dateId, kind: picked.kind, topics: picked.topics };
}

async function publishQuestions(dateId) {
  const warRef = db().collection(WARS).doc(dateId);
  const answersSnap = await warRef.collection("private").doc("answers").get();
  if (!answersSnap.exists) {
    throw new Error(`No private answers for ${dateId}`);
  }
  const uuids = answersSnap.data().uuids || [];
  await warRef.set(
    {
      question_uuids: uuids,
      status: "questions_published",
      published_at: admin.firestore.FieldValue.serverTimestamp(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  return { ok: true, dateId, count: uuids.length };
}

function scoreAnswers(selectedByUuid, correctByUuid) {
  let correct = 0;
  let wrong = 0;
  let unanswered = 0;
  for (const uuid of Object.keys(correctByUuid)) {
    const selected = selectedByUuid[uuid];
    if (selected == null || String(selected).trim() === "") {
      unanswered++;
      continue;
    }
    if (String(selected).trim().toLowerCase() === String(correctByUuid[uuid]).trim().toLowerCase()) {
      correct++;
    } else {
      wrong++;
    }
  }
  const points = Number((correct * 2 - wrong * (2 / 3)).toFixed(2));
  return { correct, wrong, unanswered, score: points };
}

async function rankWar(dateId) {
  const warRef = db().collection(WARS).doc(dateId);
  const subsSnap = await warRef
    .collection("submissions")
    .where("mode", "==", "live")
    .get();

  const rows = [];
  subsSnap.forEach((doc) => {
    const d = doc.data();
    rows.push({
      uid: doc.id,
      score: d.score || 0,
      elapsed_ms: d.elapsed_ms || 0,
      display_name: d.display_name || "",
      ref: doc.ref,
    });
  });

  rows.sort((a, b) => {
    if (b.score !== a.score) return b.score - a.score;
    return a.elapsed_ms - b.elapsed_ms;
  });

  const n = rows.length;
  const batch = db().batch();
  const top = [];
  rows.forEach((row, i) => {
    const air = i + 1;
    const percentile = n <= 1 ? 100 : Number((((n - air) / (n - 1)) * 100).toFixed(2));
    batch.set(
      row.ref,
      { air, percentile, ranked_at: admin.firestore.FieldValue.serverTimestamp() },
      { merge: true },
    );
    row.air = air;
    row.percentile = percentile;
    if (air <= 100) {
      top.push({
        uid: row.uid,
        display_name: row.display_name,
        score: row.score,
        elapsed_ms: row.elapsed_ms,
        air,
        percentile,
      });
    }
  });

  batch.set(
    warRef.collection("meta").doc("leaderboard"),
    {
      top,
      participant_count: n,
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  batch.set(
    warRef,
    {
      status: "ranked",
      participant_count: n,
      ranked_at: admin.firestore.FieldValue.serverTimestamp(),
      ranked_at_ms: Date.now(),
      updated_at: admin.firestore.FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
  await batch.commit();
  return {
    ok: true,
    dateId,
    participants: n,
    rows: rows.map((r) => ({
      uid: r.uid,
      air: r.air,
      score: r.score,
      percentile: r.percentile,
    })),
  };
}

const notif = require("./notifications");

function assertDailyWarAdmin(request) {
  if (!request.auth || !request.auth.token.email) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const email = String(request.auth.token.email).toLowerCase();
  if (!notif.isDailyWarAdminEmail(email)) {
    throw new HttpsError("permission-denied", "Not allowed.");
  }
  return email;
}

/** Blocks non-admins when RC `daily_war_admins_only` is on (or feature off). */
async function assertDailyWarParticipant(request) {
  if (!request.auth) {
    throw new HttpsError("unauthenticated", "Sign in required.");
  }
  const rollout = await notif.readDailyWarRollout();
  if (!rollout.enabled) {
    throw new HttpsError("failed-precondition", "Daily War is disabled.");
  }
  if (rollout.adminsOnly) {
    const email = (request.auth.token.email || "").toLowerCase().trim();
    if (!notif.isDailyWarAdminEmail(email)) {
      throw new HttpsError(
        "permission-denied",
        "Daily War is in admin preview.",
      );
    }
  }
}

// --- Schedules (Asia/Kolkata) ---

exports.generateDailyWar = onSchedule(
  {
    schedule: "50 5 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
  },
  async () => {
    const parts = istParts();
    await generateWarForDateId(parts.iso);
  },
);

/** N1/N7 — morning topics (war already generated at 05:50). */
exports.notifyDailyWarMorning = onSchedule(
  {
    schedule: "10 6 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
  },
  async () => {
    const parts = istParts();
    const result = await notif.notifyMorning(parts.iso);
    console.log("notifyDailyWarMorning", result);
  },
);

/** N2 — 30 minutes before start. */
exports.notifyDailyWarReminder = onSchedule(
  {
    schedule: "30 20 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
  },
  async () => {
    const parts = istParts();
    const result = await notif.notifyReminder30(parts.iso);
    console.log("notifyDailyWarReminder", result);
  },
);

/** N3 — lobby open (8:50; lobby itself opens 8:45). */
exports.notifyDailyWarLobby = onSchedule(
  {
    schedule: "50 20 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
  },
  async () => {
    const parts = istParts();
    const result = await notif.notifyLobbyOpen(parts.iso);
    console.log("notifyDailyWarLobby", result);
  },
);

exports.publishDailyWarQuestions = onSchedule(
  {
    schedule: "59 20 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
  },
  async () => {
    const parts = istParts();
    await publishQuestions(parts.iso);
  },
);

exports.rankDailyWar = onSchedule(
  {
    // After max live window (25 Q · 80s ≈ 34 min) + buffer.
    schedule: "40 21 * * *",
    timeZone: "Asia/Kolkata",
    region: "asia-south1",
  },
  async () => {
    const parts = istParts();
    const ranked = await rankWar(parts.iso);
    try {
      const rows = ranked && ranked.rows ? ranked.rows : [];
      const push = await notif.notifyResultsReady(parts.iso, rows);
      console.log("notifyResultsReady", push);
    } catch (e) {
      console.error("notifyResultsReady failed", e);
    }
  },
);

/**
 * Callable: submitDailyWar
 * data: { dateId, answers: {uuid: 'a'|'b'|...}, elapsedMs, mode?: 'live'|'unranked', displayName? }
 */
exports.submitDailyWar = onCall(
  { region: "asia-south1" },
  async (request) => {
    await assertDailyWarParticipant(request);
    const uid = request.auth.uid;
    const data = request.data || {};
    const dateId = typeof data.dateId === "string" ? data.dateId.trim() : "";
    const mode = data.mode === "unranked" ? "unranked" : "live";
    const elapsedMs = Number(data.elapsedMs) || 0;
    const answers =
      data.answers && typeof data.answers === "object" ? data.answers : null;
    const displayName =
      typeof data.displayName === "string" ? data.displayName.trim().slice(0, 60) : "";

    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId) || !answers) {
      throw new HttpsError("invalid-argument", "dateId and answers required.");
    }

    const warRef = db().collection(WARS).doc(dateId);
    const warSnap = await warRef.get();
    if (!warSnap.exists) {
      throw new HttpsError("not-found", "War not found.");
    }

    const now = Date.now();
    const startMs = Date.parse(`${dateId}T21:00:00+05:30`);
    const qCount =
      warSnap.data().question_count ||
      (warSnap.data().kind === "grand" ? 25 : WEEKDAY_QUESTION_COUNT);
    const liveEndMs = liveEndMsFor(dateId, qCount);

    if (mode === "live") {
      if (now < startMs || now > liveEndMs) {
        throw new HttpsError(
          "failed-precondition",
          "Live submissions only during the War window.",
        );
      }
    } else {
      if (now <= liveEndMs) {
        throw new HttpsError(
          "failed-precondition",
          "Unranked attempts open after the live window.",
        );
      }
    }

    const subRef = warRef.collection("submissions").doc(uid);
    const existing = await subRef.get();
    if (existing.exists && existing.data().mode === "live") {
      throw new HttpsError("already-exists", "Already submitted this War.");
    }
    if (existing.exists && mode === "unranked" && existing.data().mode === "unranked") {
      throw new HttpsError("already-exists", "Already practiced this War.");
    }

    const answersSnap = await warRef.collection("private").doc("answers").get();
    if (!answersSnap.exists) {
      throw new HttpsError("failed-precondition", "Answers not ready.");
    }
    const correctByUuid = answersSnap.data().answers || {};
    const breakdown = scoreAnswers(answers, correctByUuid);

    await subRef.set(
      {
        mode,
        score: breakdown.score,
        correct: breakdown.correct,
        wrong: breakdown.wrong,
        unanswered: breakdown.unanswered,
        elapsed_ms: Math.max(0, Math.min(elapsedMs, 30 * 60 * 1000)),
        answers,
        display_name: displayName,
        submitted_at: admin.firestore.FieldValue.serverTimestamp(),
        submitted_at_ms: now,
      },
      { merge: false },
    );

    if (mode === "live") {
      // RTDB only — do not increment Firestore war doc (home listeners).
      try {
        await bumpLiveCount(dateId, "writing");
      } catch (e) {
        console.warn("bumpLiveCount(writing) failed", e);
      }
    }

    return {
      ok: true,
      mode,
      score: breakdown.score,
      correct: breakdown.correct,
      wrong: breakdown.wrong,
      unanswered: breakdown.unanswered,
    };
  },
);

/** Admin/debug callable to generate or republish for a date. */
exports.adminGenerateDailyWar = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertDailyWarAdmin(request);
    const dateId =
      (request.data && request.data.dateId) || istParts().iso;
    const force = !!(request.data && request.data.force);
    return generateWarForDateId(dateId, { force });
  },
);

/**
 * Admin preview — reads private UUID list before public publish (20:59).
 * Does not expose correct answers by default (set includeAnswers: true to get keys).
 */
exports.adminPreviewDailyWar = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertDailyWarAdmin(request);
    const dateId =
      (request.data && request.data.dateId) || istParts().iso;
    const includeAnswers = !!(request.data && request.data.includeAnswers);

    const warRef = db().collection(WARS).doc(dateId);
    const warSnap = await warRef.get();
    if (!warSnap.exists) {
      throw new HttpsError("not-found", `No war for ${dateId}. Generate first.`);
    }
    const war = warSnap.data() || {};
    const answersSnap = await warRef.collection("private").doc("answers").get();
    if (!answersSnap.exists) {
      throw new HttpsError(
        "failed-precondition",
        "Private paper missing — generate the war first.",
      );
    }
    const privateData = answersSnap.data() || {};
    const uuids = privateData.uuids || [];
    const publicUuids = war.question_uuids || [];

    return {
      ok: true,
      dateId,
      kind: war.kind || "daily",
      status: war.status || "announced",
      topics: war.topics || [],
      next_topics: war.next_topics || [],
      question_count: war.question_count || uuids.length,
      /** Full paper UUIDs (private) — use to review in admin app before 20:59. */
      private_uuids: uuids,
      /** Empty until publish job / adminPublishDailyWar. */
      public_uuids: publicUuids,
      is_publicly_published:
        Array.isArray(publicUuids) && publicUuids.length > 0,
      ...(includeAnswers ? { answers: privateData.answers || {} } : {}),
    };
  },
);

/** Admin can force-publish private UUIDs to the public war doc (normally 20:59). */
exports.adminPublishDailyWar = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertDailyWarAdmin(request);
    const dateId =
      (request.data && request.data.dateId) || istParts().iso;
    return publishQuestions(dateId);
  },
);

/**
 * Admin test / force-send Daily War FCM.
 * data: { dateId?, phase: 'morning'|'reminder_30'|'lobby'|'results' }
 */
exports.adminNotifyDailyWar = onCall(
  { region: "asia-south1" },
  async (request) => {
    assertDailyWarAdmin(request);
    const dateId =
      (request.data && request.data.dateId) || istParts().iso;
    const phase =
      (request.data && typeof request.data.phase === "string"
        ? request.data.phase.trim()
        : "morning") || "morning";
    if (phase === "morning") return notif.notifyMorning(dateId);
    if (phase === "reminder_30") return notif.notifyReminder30(dateId);
    if (phase === "lobby") return notif.notifyLobbyOpen(dateId);
    if (phase === "results") {
      const ranked = await rankWar(dateId);
      return notif.notifyResultsReady(dateId, ranked.rows || []);
    }
    throw new HttpsError(
      "invalid-argument",
      "phase must be morning|reminder_30|lobby|results",
    );
  },
);

/**
 * Callable: joinDailyWarLobby
 * Idempotent per uid/day — bumps RTDB lobby count once (not Firestore war doc).
 * data: { dateId? }
 */
exports.joinDailyWarLobby = onCall(
  { region: "asia-south1" },
  async (request) => {
    await assertDailyWarParticipant(request);
    const uid = request.auth.uid;
    const dateId =
      (request.data && typeof request.data.dateId === "string"
        ? request.data.dateId.trim()
        : "") || istParts().iso;
    if (!/^\d{4}-\d{2}-\d{2}$/.test(dateId)) {
      throw new HttpsError("invalid-argument", "Invalid dateId.");
    }

    const warRef = db().collection(WARS).doc(dateId);
    const presenceRef = warRef.collection("lobby_presence").doc(uid);

    const firstJoin = await db().runTransaction(async (tx) => {
      const warSnap = await tx.get(warRef);
      if (!warSnap.exists) {
        throw new HttpsError("not-found", "War not found.");
      }
      const presenceSnap = await tx.get(presenceRef);
      if (presenceSnap.exists) {
        return false;
      }
      tx.set(presenceRef, {
        joined_at: admin.firestore.FieldValue.serverTimestamp(),
      });
      return true;
    });

    if (firstJoin) {
      await bumpLiveCount(dateId, "lobby");
    }
    const lobbyCount = await readLiveCount(dateId, "lobby");
    return { ok: true, lobbyCount, already: !firstJoin };
  },
);

exports._dailyWarInternals = {
  generateWarForDateId,
  publishQuestions,
  rankWar,
  istParts,
  scoreAnswers,
};
