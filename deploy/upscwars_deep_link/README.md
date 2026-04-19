# upscwars.com — share links, hosting, and local browser tests

Upload the `public/` folder to the root of **https://upscwars.com** (or merge `.well-known/` and `share/` into your CDN).

## Firestore rules (required for browser + app)

Rules for collection **`session`** live in the app repo root **[`firestore.rules`](../../firestore.rules)** (not only the snippet file).

Deploy from the repo root (where `firebase.json` references `firestore.rules`):

```bash
cd /path/to/upsc_wars
firebase deploy --only firestore:rules
```

Until this succeeds, the web player’s Firestore REST `GET` will return **403** and the Flutter app cannot create share docs.

### Behaviour

| Operation | Who | Rule |
|-----------|-----|------|
| `GET session/{id}` | Anyone (browser, curl) | `allow read: if true` |
| `CREATE session/{id}` | Signed-in user (app share) | Validated shape + limits |
| `UPDATE` / `DELETE` | — | Denied |

## Required hosted files

| Path | Purpose |
|------|---------|
| `/.well-known/apple-app-site-association` | iOS Universal Links (`Content-Type: application/json`, no redirects) |
| `/.well-known/assetlinks.json` | Android App Links |
| `/share/...` | Web player (`share/index.html` or SPA rewrite so path is `/share/test/{shareId}`) |

## Test in the browser **without** upscwars.com hosting (Mac)

Firestore reads work from **any origin** once rules allow public read. The static page expects pathname **`/share/test/{shareId}`** (same as production).

1. **Deploy rules** (see above).
2. **Create a doc** in Firebase Console → Firestore → `session` → document ID = a UUID, fields matching the app (`kind`, `subject`, `uuids`, `schemaVersion`, …), **or** use **Share** in the signed-in app and copy `shareId` from the copied URL.
3. From repo:

```bash
cd deploy/upscwars_deep_link/public
SHARE_ID='paste-your-share-uuid-here'
mkdir -p "share/test/$SHARE_ID"
cp share/index.html "share/test/$SHARE_ID/index.html"
python3 -m http.server 8765
```

4. Open in Chrome/Safari — paste the **expanded** URL (do not leave `$SHARE_ID` literally in the address bar):

`http://localhost:8765/share/test/<paste-the-same-uuid-here>/`

Example: if you set `SHARE_ID=aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee`, open  
`http://localhost:8765/share/test/aaaaaaaa-bbbb-cccc-dddd-eeeeeeeeeeee/`

Trailing slash is fine; the page reads `/share/test/{uuid}` from the path.

**404 in DevTools “Network”:**  
- **`favicon.ico` / `apple-touch-icon`**: harmless; ignored.  
- **`firestore.googleapis.com` … 404**: no document at `session/{shareId}` — create it (Share from app, or Firebase Console) and use that **exact** document ID in the URL.  
- **`firestore.googleapis.com` … 403**: deploy [`firestore.rules`](../../firestore.rules) (`firebase deploy --only firestore:rules`).

5. Answer a question, set confidence, reload the page — progress should remain (**localStorage** key `upscwars_share_v1_{shareId}`).

## Before production

1. **assetlinks.json** — Set real SHA-256 cert fingerprint(s).
2. **apple-app-site-association** — Confirm `appID` is `TEAM_ID.bundleId`.
3. **Netlify** — Use `netlify.toml` so `/share/*` serves the player page if you use a SPA layout.

## QA on devices

Universal / App Links for **`https://upscwars.com/share/*`** need real **Android + iOS** hardware after DNS + `.well-known` are live.
