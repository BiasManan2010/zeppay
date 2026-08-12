# Zep Pay

Cross-platform Flutter UPI app: one QR scan + biometric confirmation, then Android auto-dials **\*99#** or **UPI 123PAY** so the user only types their UPI PIN. Full everyday layer on top — friends, history, requests, autopay, Splitwise-parity splits.

## Stack

- Flutter + Riverpod
- Local JSON store (offline-first, hackathon-ready). Swap the store for Firestore later without rewriting UI.
- Twilio Verify via `backend/server.js` (never put the Twilio auth token in the app)
- Android Kotlin platform channel for carrier detection, `ACTION_CALL`, and call-end
- iOS: offline rails are **not available**; the UI says so and falls back to `upi://` intent

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

Live OTP:

```powershell
cd backend
npm i
$env:TWILIO_ACCOUNT_SID="ACxxx"
$env:TWILIO_AUTH_TOKEN="xxx"
$env:TWILIO_VERIFY_SID="VAxxx"
node server.js
flutter run --dart-define=TWILIO_VERIFY_URL=http://192.168.x.x:8787
```

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
