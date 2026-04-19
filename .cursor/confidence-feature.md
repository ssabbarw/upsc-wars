# Deep Link Requirements (Short Form)

## What Deep Links Must Do

**1. App-to-App Sharing**
- When user shares a battle/test/question link and recipient has the app installed → link opens directly in the app (no browser redirect)
- Format: `upscwars://share/{type}/{share_id}?ids=uuid1,uuid2...`
- Types: `battle`, `test`, `question`

**2. Universal Links (Web Fallback)**
- When recipient doesn't have app → link opens web page at `https://upscwars.com/share/{type}/{share_id}`
- Web page shows "Download App" banner at top
- Same URL works for both scenarios (OS decides app vs web)

**3. Platform Requirements**

**Android:**
- Custom URL scheme: `upscwars://`
- Android App Links: `https://upscwars.com/share/*` opens app if installed
- Needs: `AndroidManifest.xml` configuration + `assetlinks.json` hosted at `https://upscwars.com/.well-known/assetlinks.json`

**iOS:**
- Custom URL scheme: `upscwars://`
- Universal Links: `https://upscwars.com/share/*` opens app if installed
- Needs: `Info.plist` configuration + `apple-app-site-association` hosted at `https://upscwars.com/.well-known/apple-app-site-association`

**4. Routing in App**
- Deep link handler extracts `type` and `share_id` from URL
- Routes to appropriate screen:
  - `battle` → BattleLearningScreen
  - `test` → TestLearningScreen  
  - `question` → QuestionLearningScreen
- All screens in **learning mode** (forced)
- Fetch questions from local SQLite using `ids` parameter

**5. Share Link Generation**
- When user taps "Share" button → app generates link with format:
  ```
  https://upscwars.com/share/battle/{share_id}?ids=uuid1,uuid2&subject=Ancient%20History&topic=Education
  ```
- Open system share sheet with pre-filled message
- No server call needed (link is self-contained)

## What You DON'T Need

- ❌ QR codes
- ❌ SMS deep linking
- ❌ Email deep linking (standard links work fine)
- ❌ Custom domain per user (e.g., `user123.upscwars.com`)
- ❌ Dynamic link shortening (Firebase Dynamic Links) — use full URLs for now

## Critical Constraint

- Deep links **only work on physical devices** — emulators are unreliable
- Test on real Android + iOS phones before considering it "done"

---

Implement deep linking for `upscwars://` scheme and `https://upscwars.com/share/*` universal links. Handle routing to learning mode screens based on URL parameters. Configure both Android and iOS platform files for app link association.