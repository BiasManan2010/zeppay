# Zep Pay

Cross-platform Flutter UPI app: one QR scan + biometric confirmation, then Android auto-dials **\*99#** or **UPI 123PAY** so the user only types their UPI PIN. Full everyday layer on top — friends, history, requests, autopay, Splitwise-parity splits.

## Stack

- Flutter + Riverpod
- Local JSON store (offline-first, hackathon-ready). Swap the store for Firestore later without rewriting UI.
- Twilio OTP via `backend/server.js` (Messaging Service or Verify — never put the Auth Token in the app)
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

Live OTP (Twilio Programmable SMS):

```powershell
cd backend
npm i
$env:TWILIO_ACCOUNT_SID="ACxxx"
$env:TWILIO_AUTH_TOKEN="xxx"
$env:TWILIO_MESSAGING_SERVICE_SID="MGxxx"
node server.js
flutter run --dart-define=TWILIO_VERIFY_URL=http://192.168.x.x:8787
```

If you use Twilio Verify instead, set `TWILIO_VERIFY_SID` (VA…) and skip the Messaging Service SID.

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

Hero accent: `#00B4FF`  
Base: `#0A0A0F` / `#0D0D14`  
Surfaces: `#161B26`  
Failure: `#C45C4A` (never use blue for errors)

## Payment path

1. Scan QR (`mobile_scanner`) → decode VPA + amount locally  
2. Face/fingerprint (`local_auth`) — required, not skippable  
3. Connecting screen (signal-arc pulse)  
4. Android: dial `*99*1*3*<vpa>*<amount>#` or `18008913333` (Jio / 4G-only)  
5. Call-end event → confirmation (bolt → check)  
6. Transaction written to history / balance  

## Tests

```powershell
flutter test
```
