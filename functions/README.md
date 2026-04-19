# Cloud Functions (Upsc Wars)

## `sendBattleInvite`

HTTPS callable used by Flutter (`BattleInviteCloudService`). It verifies the caller is the battle host, loads the guest’s `fcm_token` from `users/{guestEmail}`, and sends FCM with `data.sessionId` for deep links.

## `sendSelfTestNotification`

HTTPS callable used by Flutter (`BattleSelfTestPushCloudService`) from **Profile → Push test**. Sends one FCM to **`users/{yourEmail}.fcm_token`** with title **Upsc Wars** and body **Success — push notifications are working.** so you can verify FCM on a **single device** without a second player.

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
