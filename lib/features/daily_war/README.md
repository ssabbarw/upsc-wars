# Daily War — build notes

Nightly All-India MCQ event (9:00 PM IST). Product name: **Daily War** / Sunday **Grand War**.

## Phases

| Phase | Status | What |
|------|--------|------|
| 0 Domain | done | schedule, curriculum (125 topics), models, scoring, Firestore paths, RC flag, rules |
| 1 Backend | done (undeployed) | `generateDailyWar`, `publishDailyWarQuestions`, `rankDailyWar`, `submitDailyWar`, `adminGenerateDailyWar` |
| 2 Clock + state | done | RTDB `.info/serverTimeOffset`, home snapshot providers |
| 3 Home hero | done | phase-driven card gated by `daily_war_enabled` |
| 4 Lobby → live → results | done (v1) | lobby start via fixed-UUID session → `/test` → `/daily-war/results` + Cloud submit |
| 5 History | done (v1) | All / Attempted / Missed list |
| 6 Push | pending | FCM topics + scheduled notification copy |

## Enable in app

Firebase Remote Config: `daily_war_enabled` = `true` (defaults **false**).

## Deploy backend

```bash
python3 tools/daily_war/rebuild_question_index.py

firebase deploy --only \
  firestore:rules,\
  functions:generateDailyWar,\
  functions:publishDailyWarQuestions,\
  functions:rankDailyWar,\
  functions:submitDailyWar,\
  functions:adminGenerateDailyWar
```

Schedules (`Asia/Kolkata`): **05:50** generate · **20:59** publish UUIDs · **21:25** rank.

## Admin seed today

Callable `adminGenerateDailyWar` `{ dateId: "YYYY-MM-DD", force: true }` as super-user email.

## Still to harden (next passes)

- Morning “Prepare these topics” → deep-link into practice drill on those topics
- Lobby live participant counter (RTDB)
- Richer results (answer review, share card, leaderboard screen)
- History: start unranked from a missed row
- Push notifications (Phase 6)
- Streak integration for War participation
