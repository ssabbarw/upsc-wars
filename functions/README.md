# Cloud Functions (Upsc Wars)

## `sendBattleInvite`

HTTPS callable used by Flutter (`BattleInviteCloudService`). It verifies the caller is the battle host, loads the guest’s `fcm_token` from `users/{guestEmail}`, and sends FCM with `data.sessionId` for deep links.

## `sendSelfTestNotification`

HTTPS callable used by Flutter (`BattleSelfTestPushCloudService`) from **Profile → Push test**. Sends one FCM to **`users/{yourEmail}.fcm_token`** with title **Upsc Wars** and body **Success — push notifications are working.** so you can verify FCM on a **single device** without a second player.

## `publishQuestionCorrection`

HTTPS callable used by Flutter (`QuestionCorrectionPublishService`) from **Settings → Internal → Question editor**.

Merges one canonical correction map (`{ uuid, meta, shared, en, hi }`) into Firestore **`question_corrections/active`**, keyed by `uuid`. Clients sync at most once per 24h and upsert locally.

Caller email must be in env **`QUESTION_EDITOR_EMAILS`** (comma-separated, lowercase).
Use the same addresses as `SuperUserEmails.emails` in
`lib/core/constants/super_user_emails.dart`.

`QUESTION_EDITOR_EMAILS=you@example.com`

Optional Remote Config **`question_corrections_revision`** (int) mirrors `active.revision` for a zero-read fast path; clients still poll Firestore daily if RC is not bumped.

## Daily CA drafts (`asia-south1`)

Python pipeline (GitHub Action at 8 PM IST Mon–Fri + Sunday) writes English drafts to **`daily_ca_drafts/{YYYY-MM-DD}`**.

| Function | Trigger | Role |
|---|---|---|
| `updateDailyCaDraft` | callable | Super-user saves edits + chosen ids |
| `publishDailyCaDay` | callable | Translates chosen 5–10 to Hindi, writes `daily_mcqs/{Y}/{M}/{D}` |
| `autoPublishDailyCa` | 5:50 AM IST | If unpublished: chosen ≥5, else first 10, skip if &lt;5 |
| `adminAutoPublishDailyCa` | callable | Manual auto-publish |

Set Functions env **`ANTHROPIC_API_KEY`** (Hindi on publish), optional **`GMAIL_SENDER` / `GMAIL_APP_PASSWORD` / `GMAIL_RECIPIENT`**.

```bash
firebase deploy --only functions:updateDailyCaDraft,functions:publishDailyCaDay,functions:autoPublishDailyCa,functions:adminAutoPublishDailyCa,firestore:rules
```

GitHub secrets for generate: `ANTHROPIC_API_KEY`, `FIREBASE_CREDENTIALS_JSON`, `FIREBASE_PROJECT_ID`, plus Gmail SMTP secrets if you want the summary email.

## `sendSpotTestNotification`

HTTPS callable used by Flutter (`SpotTestPushCloudService`) from **Settings → Internal → Spot test composer**.

- `target: self` (default) — one FCM to **`users/{yourEmail}.fcm_token`**
- `target: broadcast` — FCM to topic **`upsc_wars_spot_tests`** (all app clients subscribe on token sync). Caller email must be listed in env **`SPOT_TEST_BROADCAST_EMAILS`** (comma-separated, lowercase).

Set in **Firebase Console → Functions → sendSpotTestNotification → Environment variables**:

`SPOT_TEST_BROADCAST_EMAILS=you@example.com,other@example.com`

## Setup

```bash
npm install -g firebase-tools
firebase login
cd ..   # repo root (parent of functions/)
firebase use --add
cd functions && npm install
```

## Deploy

From **repo root** (where `firebase.json` is):

```bash
firebase deploy --only functions
```

Or:

```bash
firebase deploy --only functions:sendBattleInvite,functions:sendSelfTestNotification
```

After changing `index.js`, redeploy so **structured logs** appear in **Firebase Console → Functions → sendBattleInvite → Logs** (or `firebase functions:log`).

## Troubleshooting

| Symptom | Check |
|--------|--------|
| `permission-denied` | Signed-in email must match `battle_matches/{id}.host_email`. |
| `no_token` | Guest signed in once so `users/{email}.fcm_token` exists. |
| `send_failed` | FCM/APNs setup in Firebase Console; token not expired. |
| Callable missing | Same Firebase project as the app; deploy succeeded. |

Default region for 1st gen callables is **us-central1**, matching Flutter `FirebaseFunctions.instance`.

Functions use **Node.js 22** (`functions/package.json` → `engines.node`). Redeploy after changing the engine line.

## Community traffic bots

Server-only. No app release. Recents, battle accept/send, blank QOTD, sparse Open Challenge, and Daily War participation.

Growth is gradual so Recents does not jump overnight:

- Day 1: **5** unique bots appear across the day (first-seen staggered, not all at once).
- Day 2: **8**. Then **+3 per day**, capped at **100 unique bots per IST day**.
- Each night **15–30%** of yesterday’s faces skip today (last-seen ages off naturally).
- The same share of **new or returning** faces trickle in during waking hours (7:20–22:40 IST), at least a few minutes apart.
- Only **12–20%** of today’s already-seen bots look “just now” in any hour (cap 12).

To **retract** when real traffic shows up, set Remote Config `bots_appear_per_day_target` lower (e.g. `20` or `0`). Each IST day the unique-bot count falls by at most `bots_retract_per_day` (default **8**), with **no new names** during the wind-down. From 100 → 20 takes about 10 days; 100 → 0 about 13. Takes effect on the **next IST day plan** (or the next `tickBots` after midnight). Emergency off: `bots_enabled = false`.

Deploy (from repo root):

```bash
firebase deploy --only functions:tickBots,functions:onBotBattleMatchWritten,functions:adminRunBotTick,functions:adminPlanBotDay,functions:sendBattleInvite,firestore:rules
```

Or deploy all functions. After the first deploy, wait up to 5 minutes for `tickBots`, or call **`adminRunBotTick`** (admin email).

Optional Remote Config keys (code defaults apply if missing):

| Key | Default | Meaning |
|-----|---------|---------|
| `bots_enabled` | true | Master switch |
| `bots_day1_count` | 5 | Unique bots on day 1 |
| `bots_day2_count` | 8 | Unique bots on day 2 |
| `bots_growth_per_day` | 3 | Added each day after day 2 |
| `bots_appear_per_day_max` | 100 | Daily unique-appear cap |
| `bots_appear_per_day_target` | 100 | Desired unique bots/day; lower this to retract |
| `bots_retract_per_day` | 8 | Max unique-bot drop per IST day |
| `bots_daily_drop_min` / `max` | 0.15 / 0.30 | Skip yesterday’s faces |
| `bots_online_fraction_min` / `max` | 0.12 / 0.20 | Share “just now” this hour |
| `bots_online_per_hour_cap` | 12 | Max concurrent fresh last-seen |
| `bots_tick_minutes` | 5 | Presence refresh floor |
| `bots_battles_per_day_max` | 3 | Per bot, incoming + outgoing |
| `bots_accept_rate` | 0.55 | Chance a bot accepts an invite |
| `bots_outgoing_invites_per_day` | 3 | Pool total per day |
| `bots_qotd_per_day` | 1 | Blank-comment QOTD posts |
| `bots_open_challenge_every_n_days` | 4 | Open Challenge cadence |
| `bots_daily_war_fraction` | 0.4 | Share of today’s bots in the War |
| `bots_same_user_cooldown_days` | 2 | Same human vs same bot |

Bots have no photo, Telegram, or Instagram. They never reply to chat. Profiles live in `users/` with `isBot: true`; roster/jobs are Admin-only (`bot_roster`, `bot_jobs`, `bot_state`).

