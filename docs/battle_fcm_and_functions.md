# Battle invites: FCM and Cloud Functions

The app sends human battle invites by calling the HTTPS callable **`sendBattleInvite`** and opens join links via **`/battle/join/:sessionId`** (see `BattleMessagingService`).

## Client behaviour

- **FCM**: `firebase_messaging` requests permission (non-web), subscribes to `onMessageOpenedApp`, and handles `getInitialMessage` after the first frame (`UpscWarsApp`).
- **Data payload**: include a string field **`sessionId`** (UUID of the shared Drift session / `battle_matches` document id). The client navigates to `go_router` path **`/battle/join/<sessionId>`**.
- **Callable** (`BattleInviteCloudService`): invokes `FirebaseFunctions.instance.httpsCallable('sendBattleInvite')` with:
  - `guestEmail` — invitee’s email (lowercase), must match `users/{email}` if you read FCM token from there.
  - `sessionId`
  - `hostDisplayName`
  - `subjectLabel` — subject string for notification body.

If the function is not deployed, the call fails silently in debug (logged); the host can still share the session id manually.

## Deployed implementation

Source of truth: **`functions/index.js`** in this repo (with `firebase.json` at the project root).

The callable:

1. Requires `context.auth` with **`email`** on the ID token.
2. Loads **`battle_matches/{sessionId}`** and checks **`battle_mode === 'human'`**, caller is **`host_email`**, and **`guest_email`** matches the request’s `guestEmail`.
3. Reads **`users/{guestEmail}`** and uses **`fcm_token`** or **`fcmToken`**.
4. Sends FCM **`data.sessionId`** (string) for `BattleMessagingService`.

**Deploy** (from repo root): `firebase use --add` once, then `firebase deploy --only functions` (or deploy `sendBattleInvite` and `sendSelfTestNotification` together). See **`functions/README.md`** for setup and troubleshooting.

**Self test:** Callable **`sendSelfTestNotification`** sends a “Success” notification to the signed-in user’s own FCM token (Profile → **Send test notification**). Payload includes `data.kind=self_test` (no `sessionId`, so the app will not open the join route).

## Firestore: `battle_matches/{sessionId}`

Clients read/write match metadata and `joined_users`. Deploy rules that:

- Allow the **host** to create the match document and both `joined_users` stubs when starting a human battle.
- Allow the **guest** (`guest_email`) to **merge** their own `joined_users/{guestEmail}` document.
- Allow both participants to update **`responses`** on their own doc only.

## Storing the invitee’s FCM token

The app writes **`fcm_token`** (and `fcm_token_updated_at`) on `users/{lowercaseEmail}` via **`FcmTokenSyncService`**: after sign-in (`authStateChanges` in `UpscWarsApp`) and on **`FirebaseMessaging.onTokenRefresh`**. The Cloud Function reads that field to send the invite.

## Universal Links / App Links

Point your HTTPS domain at the app and map paths like `/battle/join/*` to the Flutter deep link handler so notification taps open the same route as in-app navigation.
