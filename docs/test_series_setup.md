# Prelims Test Series: setup checklist

The code is complete end to end. These are the steps only you can do (accounts, consoles, credentials). Do them in this order.

## How it fits together

| Piece | Where |
| --- | --- |
| Generator (static, PYQ-mix, mock shells) | `tools/test_series/generate_series.py` |
| Upload to Firestore | `functions/scripts/upload_test_series.js` |
| Monthly CA tests + mock CA slots | `functions/test_series/` (scheduled daily 06:00 IST, `publishTestSeriesDue`) |
| App feature | `lib/features/test_series/` |
| Purchase | RevenueCat (`purchases_flutter`), Android only |
| Sales switch | Firebase Remote Config |

Access control is client-side (RevenueCat entitlement). Static and PYQ questions ship inside the app, so a determined user could extract them. That is accepted for v1. Current-affairs questions come from the existing Daily CA collection.

## 1. Google Play Console

1. Create a **one-time product** (Monetize > Products > One-time products) with product id `prelims_2027_pass`. Set the price and activate it.
   - A release of the app with the billing library must be uploaded to at least an internal testing track before products can be tested.
2. Add your tester Gmail accounts under Settings > License testing.
3. Create a Google Cloud **service account** with Play access and link it in Play Console (Users and permissions) as RevenueCat requires. RevenueCat's "Google Play" setup screen walks you through it.

## 2. RevenueCat

1. Create a project and add an **Android app** with your package name.
2. Upload the Play service account JSON in the app's settings.
3. Create a product with the identifier `prelims_2027_pass` (store product id) and attach it to a new **entitlement** called `prelims_2027`. (An offering is not needed; the app loads the product directly.)
4. Copy the **public Android SDK key** (starts with `goog_`).
5. Build with the key:

   ```bash
   flutter run --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxx
   flutter build appbundle --dart-define=REVENUECAT_ANDROID_KEY=goog_xxxxxxxx
   ```

   Without the key the feature still works for free tests; purchase is simply unavailable.

Next year: add `prelims_2028_pass` / entitlement `prelims_2028`, generate with `--series-id prelims_2028`, and change `test_series_active_id`. Old buyers keep `prelims_2027`.

## 3. Android launch mode (please check)

`android/app/src/main/AndroidManifest.xml` uses `android:launchMode="singleTask"` for the main activity. RevenueCat advises `standard` or `singleTop`, because `singleTask` can cancel the Play purchase sheet in some cases. If you see purchases cancelling on a real device, change it to `singleTop` and retest notification taps and deep links.

## 4. Firebase

### Remote Config keys

| Key | Meaning | Default |
| --- | --- | --- |
| `test_series_sales_enabled` | `true` = new users see and can buy the series. `false` = hidden for everyone who has not bought it. Buyers always keep access. | `false` |
| `test_series_active_id` | Series currently on sale. | `prelims_2027` |

Set `test_series_sales_enabled` to `true` and publish the template when you are ready to launch.

### Rules and functions

```bash
firebase deploy --only firestore:rules,functions
```

`firestore.rules` allows **public read** of `test_series/**` so signed-out users can preview the catalog (writes are server only). Purchase still requires Google/Apple sign-in in the app.

### Admin credentials for the scripts

Create a Firebase Admin service account key (Project settings > Service accounts > Generate key) and keep it **outside the repo** (the `.gitignore` already blocks `service-account*.json`). Use it through `GOOGLE_APPLICATION_CREDENTIALS`.

## 5. Generate and upload the series

```bash
# 1. Check how deep the Current Affairs archive is (per month)
cd functions
GOOGLE_APPLICATION_CREDENTIALS=/path/key.json node scripts/count_ca_archive.js

# 2. Generate (builds a fresh question DB first; deterministic with --seed)
cd ..
python3 tools/test_series/generate_series.py \
    --series-id prelims_2027 --launch-date 2026-10-17 --prelims-date 2027-05-23

# 3. Upload (dry run first). Existing tests are skipped unless --force.
cd functions
GOOGLE_APPLICATION_CREDENTIALS=/path/key.json \
  node scripts/upload_test_series.js ../tools/test_series/out/prelims_2027.json --dry-run
GOOGLE_APPLICATION_CREDENTIALS=/path/key.json \
  node scripts/upload_test_series.js ../tools/test_series/out/prelims_2027.json

# 4. Publish everything already due (launch-day CA test and first mock)
GOOGLE_APPLICATION_CREDENTIALS=/path/key.json \
  node scripts/publish_test_series_due.js prelims_2027 --dry-run
GOOGLE_APPLICATION_CREDENTIALS=/path/key.json \
  node scripts/publish_test_series_due.js prelims_2027
```

After this the deployed function `publishTestSeriesDue` runs daily at 06:00 IST. On the 1st of each month it fills that month's CA test, and on each mock's unlock date it fills the mock's CA slots. A test with fewer than 20 usable CA questions is left pending and retried the next day. Admins can also trigger it from the app via the callable `adminPublishTestSeriesDue`.

Re-run `upload_test_series.js` only with `--force` if you want to replace tests (this overwrites published CA tests too).

## 6. Test the purchase flow

1. Install a build signed with your upload key from the internal testing track on a device whose Gmail is a license tester.
2. Open Today > Prelims Test Series (turn `test_series_sales_enabled` on first, or sign in as a superuser).
3. Tap a locked test, confirm the Google sign-in prompt, then buy. Test purchases are free for license testers.
4. Check: locked tests open, "My Test Series" appears under Settings, and uninstall/reinstall plus **Restore purchases** brings the access back.
5. Turn `test_series_sales_enabled` off and confirm a fresh account no longer sees the entry, while the buyer still does.

## 7. Offer codes (free access for influencers)

Give the series away with codes, without touching Google Play or RevenueCat. Super users manage them in the app: **Settings > Offer codes**.

```bash
firebase deploy --only firestore:rules,functions
```

| Want | Do |
| --- | --- |
| A code for an influencer | **New code**. Label it with their name. Optional: your own code text (for example `RAHUL50`), **Max people**, and a **last valid day**. Share the code. People enter it under **Have a code?** in the unlock sheet. |
| Count who used it | The code's row shows `N of max redeemed` and a status (Active, Expired, Limit reached, Disabled). Tap the row for the emails and times. |
| Switch a code off | The switch on its row. |

What the user sees: after the last valid day (it works until 11:59 PM that day) the field says **Code expired**. Once the max is reached it says **Code limit reached**. Unknown or disabled codes say "That code isn't valid".

How it works:

- A redemption writes `test_series_grants/{firebaseUid}` through a Cloud Function (`redeemTestSeriesCode`). The app unions these grants with RevenueCat entitlements, so it behaves exactly like a purchase.
- Grants belong to the Google/Apple account (a real account is required, anonymous users are asked to sign in first). They survive reinstalls and work on any device after signing in. **Restore purchase** re-reads both RevenueCat and the grants; if neither has anything it says "Nothing was found" and the buy button stays available.
- Expiring, disabling or filling up a code never removes access that was already granted.
- The same user cannot use up two redemptions: if they already own the series, the code is not consumed.
- Codes are case-insensitive. After 8 unknown codes in an hour an account is throttled.
- Codes are only reachable where the user can reach the series, so keep `test_series_sales_enabled` on while codes are in use.

## Behaviour notes

- A purchase is tied to the Google account (sign-in is required before paying), so it restores on any device.
- One scored attempt per test (exam mode, timed, +2 / -0.66). After that the user can review it and practise again unscored; practice never touches series stats.
- The month of each current-affairs question is stored but never shown.
- Free tests (14): 6 PYQ-mix, the first test of each of the 6 subject groups, the first CA test and the first mock.
- Prelims 2027 date defaults to 2027-05-23. Change it with `--prelims-date` and regenerate if UPSC announces a different date.
