# Firestore schema: `battle_matches`

Battles use a **flat** collection `battle_matches/{sessionId}` where `sessionId` is the shared Drift session UUID (same id the app uses in local SQLite / deep links).

## Match document (`battle_matches/{sessionId}`)

| Field | Type | Description |
|--------|------|-------------|
| `battle_mode` | string | `human` or `bot` (see `BattleMatchFirestoreService`). |
| `host_email` | string | Lowercase email of the host. |
| `host_display_name` | string | Display name for UI / invites. |
| `guest_email` | string? | Lowercase invitee email for human battles; null for bot. |
| `guest_display_name` | string | Guest or synthetic opponent label. |
| `subject` | string | Subject label for the battle. |
| `question_uuids` | array of strings | Canonical question order for both devices. |
| `question_indexes` | array of numbers | Legacy-shaped indices `0..n-1` (parallel to `question_uuids`). |
| `guest_ready` | bool | Human battles: `false` at create; set to `true` when the guest finishes join + local session import (`signalGuestLobbyReady`). Host lobby enables **Start battle** when this is `true`. |
| `lets_start_game` | bool | Human: `false` until the host taps **Start battle** (`signalHostStartedBattle`); then both clients enter the timed test. Bot matches use `true` immediately. |
| `num_of_players_joined` | number | `1` until guest joins; `2` after guest completes join flow. |
| `fcm_token` | null | Reserved; prefer **`users/{email}.fcm_token`** for targeting. |

## Subcollections

### `joined_users/{participantDocId}`

`participantDocId` is lowercase email for humans, or `opponent` for the synthetic bot doc.

| Field | Type | Description |
|--------|------|-------------|
| `display_name` | string | Shown in scoreboard. |
| `profile_pic` | string? | URL or `no_image`. |
| `game_progress_status` | string | e.g. `Active`. |
| `responses` | array of numbers | Per-question legacy encoding: `0` none, `1`–`4` = A–D. |

### `joined_users_game_over_statuses/{participantDocId}`

| Field | Type | Description |
|--------|------|-------------|
| `game_progress_status` | string | e.g. `Active`. |

## Security rules

Authoritative rules for deployment live in the repo root: **`firestore.rules`**.

They enforce:

- Authenticated reads on `battle_matches` metadata (join flow + in-battle sync).
- Match **create** only by the declared host (`host_email` matches signed-in email, lowercased).
- Match **update** by the **guest** for `guest_ready` + `num_of_players_joined` after join; by the **host** for `lets_start_game` when starting the battle.
- `joined_users` / game-over docs: each participant writes **only their own** doc id (email or `opponent` for bot host).

See also [`battle_fcm_and_functions.md`](battle_fcm_and_functions.md) for FCM payloads and callable `sendBattleInvite`.
