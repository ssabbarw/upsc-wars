const fs = require("fs");
const path = require("path");
const { hashString, mulberry32, randInt } = require("./time");

const BATTLE_SUBJECTS = [
  "Polity",
  "Geography",
  "Economy",
  "Environment",
  "Ancient History",
  "Medieval History",
  "Modern History",
  "Art and Culture",
];

const SUBJECT_PREFIX = {
  Polity: "polity",
  Geography: "geography",
  Economy: "economy",
  Environment: "environment",
  "Ancient History": "ancient_history",
  "Medieval History": "medieval_history",
  "Modern History": "modern_history",
  "Art and Culture": "art_and_culture",
};

let _index = null;
let _flat = null;
let _byUuid = null;

function questionIndex() {
  if (_index) return _index;
  const p = path.join(__dirname, "../daily_war/question_index.json");
  _index = JSON.parse(fs.readFileSync(p, "utf8"));
  return _index;
}

function flatQuestions() {
  if (_flat) return _flat;
  const index = questionIndex();
  _flat = [];
  _byUuid = {};
  for (const [key, rows] of Object.entries(index)) {
    const prefix = key.split("::")[0];
    for (const r of rows || []) {
      if (!r || !r.u) continue;
      const row = { uuid: r.u, correct: String(r.c || "a").toLowerCase(), prefix };
      _flat.push(row);
      _byUuid[r.u] = row;
    }
  }
  return _flat;
}

function correctForUuid(uuid) {
  flatQuestions();
  const row = _byUuid[uuid];
  return row ? row.correct : null;
}

function questionsForSubject(subject) {
  const prefix = SUBJECT_PREFIX[subject];
  const all = flatQuestions();
  if (!prefix) return all;
  const scoped = all.filter((q) => q.prefix === prefix);
  return scoped.length >= 10 ? scoped : all;
}

function pickQuestions(subject, count, seed) {
  const pool = [...questionsForSubject(subject)];
  const rng = mulberry32(hashString(seed || `${subject}:${count}:${Date.now()}`));
  for (let i = pool.length - 1; i > 0; i--) {
    const j = Math.floor(rng() * (i + 1));
    [pool[i], pool[j]] = [pool[j], pool[i]];
  }
  return pool.slice(0, count);
}

function pickSubject(seed) {
  const rng = mulberry32(hashString(seed || "subject"));
  return BATTLE_SUBJECTS[Math.floor(rng() * BATTLE_SUBJECTS.length)];
}

const OPTIONS = ["a", "b", "c", "d"];

function plannedAnswer(correct, skill, rng) {
  if (rng() < 0.08) return null;
  const c = String(correct || "a").toLowerCase();
  if (rng() < skill) return c;
  const wrong = OPTIONS.filter((o) => o !== c);
  return wrong[Math.floor(rng() * wrong.length)];
}

function optionToResponseInt(option) {
  switch (String(option || "").toLowerCase()) {
    case "a":
      return 1;
    case "b":
      return 2;
    case "c":
      return 3;
    case "d":
      return 4;
    default:
      return 0;
  }
}

function skillForBot(bot) {
  const s = Number(bot && bot.skill);
  if (Number.isFinite(s) && s > 0 && s < 1) return s;
  return 0.48;
}

module.exports = {
  BATTLE_SUBJECTS,
  pickQuestions,
  pickSubject,
  correctForUuid,
  plannedAnswer,
  optionToResponseInt,
  skillForBot,
  randInt,
};
