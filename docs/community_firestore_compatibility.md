# Community Firestore Compatibility (Legacy -> Current)

This document locks Phase 0 compatibility for Community migration.

## Collections

- `users`:
  - Document ID = user email in lowercase
  - Used by `Recent`, `Challengers`, and settings write-backs
- `buckets`:
  - Path shape: `buckets/{yyyy-m}/{day}/{bucketName}`
  - Document payload is map `{email: userDataMap}` for recently-online snapshots
  - On app open (signed-in), the app **merges** the current user under their lowercase email with fields including `name`, `optional`, `email`, `telegram`, `insta`, `photoURL`, `my_status`, `isInBattle`, `fcm_token`, `phoneModel`, `appVersion`, `lastOnlineTime` (see `CommunityBucketPresenceService`).

## Field Mapping

| Legacy field | New model field | Notes |
| --- | --- | --- |
| `email` | `CommunityUser.email` | fallback to doc id |
| `name` | `CommunityUser.name` | default `UPSC Warrior` |
| `photoURL` | `CommunityUser.photoUrl` | fallback avatar URL |
| `lastOnlineTime` | `CommunityUser.lastOnlineTime` | epoch millis |
| `acceptingBattleInvites` | `CommunityUser.acceptingBattleInvites` | default true |
| `isInBattle` | `CommunityUser.isInBattleTill` | treated as `in battle till` timestamp |
| `appVersion` | `CommunityUser.appVersion` | optional |
| `telegram` | `CommunityUser.telegram` | optional |
| `insta` | `CommunityUser.instagram` | optional |
| `optional` | `CommunityUser.optionalContact` | optional |
| `my_status` | `CommunityUser.status` | optional |
| `kKeyLastOpenChallengeFloatDate` | `CommunityUser.openChallengeTimestamp` | used in challengers query |
| `kKeyLastOpenChallengeSubject` | `CommunityUser.openChallengeSubject` | optional display |

## Local Preference Keys (Settings)

- `community_show_in_battle_status` (new local key for migrated UI)
- `community_accepting_battle_invites` (new local key for migrated UI)

## Deferred / Out of Scope in this migration

- QOTD feeds and related Firestore paths
- Ad units and interstitial triggering logic
- Legacy bot isolate internals (random connect only via current app-safe entry point)
