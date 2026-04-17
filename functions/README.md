# Cloud Functions (UPSC Wars)

## `sendBattleInvite`

HTTPS callable used by Flutter (`BattleInviteCloudService`). It verifies the caller is the battle host, loads the guest’s `fcm_token` from `users/{guestEmail}`, and sends FCM with `data.sessionId` for deep links.

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
firebase deploy --only functions:sendBattleInvite
```

## Troubleshooting

| Symptom | Check |
|--------|--------|
| `permission-denied` | Signed-in email must match `battle_matches/{id}.host_email`. |
| `no_token` | Guest signed in once so `users/{email}.fcm_token` exists. |
| `send_failed` | FCM/APNs setup in Firebase Console; token not expired. |
| Callable missing | Same Firebase project as the app; deploy succeeded. |

Default region for 1st gen callables is **us-central1**, matching Flutter `FirebaseFunctions.instance`.
