# upscwars.app — Universal Links / App Links hosting

Upload the `public/` folder contents to the root of **https://upscwars.app** (or merge `.well-known/` and `share/` into your existing site).

## Required files

| Path | Purpose |
|------|---------|
| `/.well-known/apple-app-site-association` | iOS Universal Links (no file extension; `Content-Type: application/json`) |
| `/.well-known/assetlinks.json` | Android App Links verification |
| `/share/index.html` | Web fallback: loads `session/{shareId}` from Firestore (REST), runs practice UI, saves progress in **localStorage** |

## Firestore `session` collection

The Flutter app writes **`session/{shareId}`** when the user shares (requires **signed-in** user per default rules). Fields:

- `kind`, `subject`, optional `topic`
- **`uuids`**: array of question JSON maps (same shape as [test_question_share_map.dart](../../lib/core/domain/entities/test_question_share_map.dart))
- `createdAt`, `schemaVersion`

Merge **`firestore.rules.snippet`** into your project `firestore.rules` and deploy with `firebase deploy --only firestore:rules`.

## Before going live

1. **assetlinks.json** — Replace `REPLACE_WITH_RELEASE_KEY_SHA256` with your **release** keystore SHA-256 fingerprint (`keytool -list -v -keystore …`). Add the debug fingerprint only for staging if needed.
2. **apple-app-site-association** — Confirm `appID` is `TEAM_ID.BUNDLE_ID` (`PJFA69Q3GT.tinyminyapps.upsc.wars` matches the Xcode project at time of writing).
3. Serve **AASA** without redirects (Apple validates `https://upscwars.app/.well-known/apple-app-site-association` with HTTP 200 and JSON body).
4. **Netlify** — If you use Netlify, copy `netlify.toml` to the site root so `/share/*` serves the fallback HTML.

## QA

Test cold and warm opens of both `https://upscwars.app/share/...` and `upscwars://share/...` on **physical** Android and iOS devices (emulators are unreliable for domain verification).
