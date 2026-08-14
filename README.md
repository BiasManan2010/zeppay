# Zep Pay

Cross-platform Flutter UPI app: one QR scan + biometric confirmation, then Android auto-dials **\*99#** or **UPI 123PAY** so the user only types their UPI PIN. Full everyday layer on top — friends, history, requests, autopay, Splitwise-parity splits.

## Stack

- Flutter + Riverpod
- Local JSON store (offline-first, hackathon-ready). Swap the store for Firestore later without rewriting UI.
- Twilio OTP via `backend/server.js` on **Render** (Messaging Service or Verify — never put the Auth Token in the app)
- Android Kotlin platform channel for carrier detection, `ACTION_CALL`, and call-end
- iOS: offline rails are **not available**; the UI says so and falls back to `upi://` intent

## Android demo APK

GitHub Actions builds a signed-with-debug-keys release APK on every push to `main`.

- **Actions artifact:** [github.com/BiasManan2010/zeppay/actions](https://github.com/BiasManan2010/zeppay/actions) → latest run → `zeppay-apk`
- **Release download:** [github.com/BiasManan2010/zeppay/releases](https://github.com/BiasManan2010/zeppay/releases)

Install on a phone: download `app-release.apk` → allow unknown sources → open the file. Dev OTP is **123456**. Offline `*99#` / 123PAY needs a real SIM.

## First run

Flutter SDK on this machine: `C:\Users\dpsa0\flutter\bin`

```powershell
$env:Path = "C:\Users\dpsa0\flutter\bin;" + $env:Path
cd C:\Users\dpsa0\Desktop\zeppay
flutter create . --org in.zeppay --project-name zeppay --platforms android,ios
flutter pub get
flutter run
```

`flutter create .` fills Gradle wrapper, iOS Xcode project, and launcher icons without overwriting `lib/`.

Dev OTP (no Twilio): **123456**

Live OTP: deploy `backend/` to Render, then point the app at that URL (see **Render** below). For LAN debugging only:

```powershell
cd backend
npm i
$env:TWILIO_ACCOUNT_SID="ACxxx"
$env:TWILIO_AUTH_TOKEN="xxx"
$env:TWILIO_MESSAGING_SERVICE_SID="MGxxx"
npm start
flutter run --dart-define=TWILIO_VERIFY_URL=http://192.168.x.x:8787
```

If you use Twilio Verify instead, set `TWILIO_VERIFY_SID` (VA…) and skip the Messaging Service SID.

## Render (OTP + Supabase proxy)

The Node proxy is a Render **Web Service**. Secrets stay in Render — never in Flutter `--dart-define` or git.

1. [dashboard.render.com](https://dashboard.render.com) → **New** → **Web Service** → this GitHub repo.
2. **Root Directory:** `backend`
3. **Runtime:** Node. **Build:** `npm install --omit=dev`. **Start:** `npm start`
4. Instance can be free; Render injects `PORT`. Opening the site URL or `GET /health` returns JSON `{ "ok": true, ... }` — this is an API, not a website.
5. Environment (same keys as `backend/env.example`):

| Key | Notes |
| --- | --- |
| `TWILIO_ACCOUNT_SID` | `AC…` |
| `TWILIO_AUTH_TOKEN` | rotate if it was ever pasted in chat |
| `TWILIO_MESSAGING_SERVICE_SID` | `MG…` (or `TWILIO_FROM` / `TWILIO_VERIFY_SID`) |
| `SUPABASE_URL` | `https://xxxx.supabase.co` |
| `SUPABASE_SERVICE_ROLE_KEY` | service_role, not anon |
| `OTP_PEPPER` | optional extra salt |

Or apply `render.yaml` (Blueprint). Fill the `sync: false` vars in the dashboard.

After deploy, the public URL is `https://<service>.onrender.com` (no trailing slash).

- Phone: **Settings → OTP PROXY URL**
- Builds: `--dart-define=TWILIO_VERIFY_URL=https://<service>.onrender.com`
- GitHub Actions: repo secret `TWILIO_VERIFY_URL` = that same URL

Free Render services sleep after idle; the first OTP after sleep can take ~30s.

## Supabase (user count + OTP login)

Paste `supabase/schema.sql` into the Supabase SQL editor. Then:

```powershell
$env:SUPABASE_URL="https://YOUR_PROJECT.supabase.co"
$env:SUPABASE_SERVICE_ROLE_KEY="eyJ..."
```

`app_users` is only a hashed phone (how many people signed in). `otp_logins` holds the login phone and a hash of the SMS code until it is used or expires. No UPI, name, or bank data is uploaded.

## Android permissions

`CALL_PHONE`, `CAMERA`, `USE_BIOMETRIC`, `READ_PHONE_STATE` — declared in `AndroidManifest.xml`. The telephony bridge lives in `android/app/src/main/kotlin/in/zeppay/app/TelephonyBridge.kt`.

`MainActivity` extends `FlutterFragmentActivity` so `local_auth` can show the biometric prompt.

## Design tokens

All colors live in `lib/core/theme/app_colors.dart`. Do not hardcode hex in screens.

Hero accent: `#3BA3FF`  
Base: charcoal `#1C1C1E` / `#2C2C2E` (grey-black, not a blue wash)  
Surfaces: `#3A3A3C`  
Failure: `#C45C4A` (never use blue for errors)

## Payment path

1. Scan a UPI QR  
2. Enter the amount and pick what you are spending on  
3. Android dials `*99#` / 123PAY (or opens UPI) so the user types their **UPI PIN**  
4. Call-end → confirmation  

Contacts are read-only (`READ_CONTACTS` only). OTP defaults to `https://zeppay.onrender.com`.

## Tests

```powershell
flutter test
```
