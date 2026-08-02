# Daily War — build notes

Nightly All-India MCQ event (9:00 PM IST). Product name: **Daily War** /
Saturday **Grand War** · **Sunday off**.

## Phases

| Phase | Status | What |
|------|--------|------|
| 0 Domain | done | schedule, curriculum (125 topics), models, scoring, Firestore paths, RC flag, rules |
| 1 Backend | done (undeployed) | `generateDailyWar`, `publishDailyWarQuestions`, `rankDailyWar`, `submitDailyWar`, `adminGenerateDailyWar` |
| 2 Clock + state | done | RTDB `.info/serverTimeOffset`, home snapshot providers |
| 3 Home hero | done | phase-driven card gated by `daily_war_enabled` |
| 4 Lobby → live → results | done (v1) | lobby start via fixed-UUID session → `/test` → `/daily-war/results` + Cloud submit |
| 5 History | done (v1) | All / Attempted / Missed list |
| 6 Push | done | FCM topic `upsc_wars_daily_war` · morning 06:10 · reminder 20:30 · lobby 20:50 · ranks after 21:25 |

## Enable in app

Firebase Remote Config:

| Key | Type | Meaning |
|-----|------|---------|
| `daily_war_enabled` | Boolean | Master switch (app/server default **true**) |
| `daily_war_admins_only` | Boolean | Default **true** — only super-users. Set **false** for everyone. |

Admin emails match in-app super users (`sachinsabbarwal@…`, `upscwars@…`, etc.).

FCM topics: `upsc_wars_daily_war` (everyone) · `upsc_wars_daily_war_admins` (admin preview). Clients subscribe to the matching topic after token sync.

## Deploy backend

```bash
python3 tools/daily_war/rebuild_question_index.py

firebase deploy --only \
  firestore:rules,\
  functions:generateDailyWar,\
  functions:publishDailyWarQuestions,\
  functions:rankDailyWar,\
  functions:notifyDailyWarMorning,\
  functions:notifyDailyWarReminder,\
  functions:notifyDailyWarLobby,\
  functions:submitDailyWar,\
  functions:adminGenerateDailyWar,\
  functions:adminNotifyDailyWar
```

Schedules (`Asia/Kolkata`):

| Time | Job |
|------|-----|
| **05:50** | generate (private paper) |
| **06:10** | morning topics push (N1 / Grand N7) |
| **20:30** | “War in 30 minutes” push (N2) |
| **20:50** | lobby open push (N3) |
| **20:59** | copy UUIDs to public |
| **21:40** | rank + results push (after live window sized from Q count) |

Admin dashboard → **Push: morning / lobby / results** to test without waiting for cron.