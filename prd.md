# Product Requirements Document
## Offline UPI Payment App

**Event:** Hackathon, August 22–23
**Platform:** Native Android (Kotlin + Jetpack Compose)

---

## 1. Problem Statement

Millions of UPI transactions fail or become impossible every day due to poor or zero internet connectivity. NPCI already provides offline-capable payment rails — **\*99# (USSD)** and **UPI 123PAY (IVR)** — that work over basic cellular signal alone, with no data or WiFi required. But using them today is difficult:

- Manually dialing cryptic USSD codes
- Typing a full UPI ID character-by-character on a numeric keypad
- Navigating a multi-step voice or text menu (roughly 7–8 steps per payment)
- **\*99# does not work at all on Jio's network**, since Jio runs a 4G/VoLTE-only infrastructure without the legacy USSD signaling layer — a major gap given Jio's user base

As a result, a functioning offline payment system exists but is barely used, and a large portion of India's largest carrier's users can't use it at all.

---

## 2. Our Solution

An Android app that turns the entire offline payment process into a single scan and a biometric confirmation — while adding a full personal-finance layer (balances, history, splitting, autopay) on top, so it functions as a complete everyday payments app, not just an offline fallback tool.

**Core innovation:** automatic detection of the user's carrier and network condition, routing the payment through whichever rail actually works for them — \*99# where supported, UPI 123PAY IVR as an automatic fallback for Jio and 4G-only users — all triggered from one QR scan, with no manual dialing or menu navigation required from the user.

---

## 3. App Features

### 3.1 Onboarding & Account
- Phone number login with OTP verification (Twilio)
- Bank account / UPI linking during setup
- Biometric (face) authentication enrollment, required for every payment confirmation

### 3.2 Core Payment Flow (Offline-Capable)
- QR code scanning — decodes VPA (UPI ID) and amount locally, works with zero internet
- Automatic carrier detection — identifies Jio vs. other carriers to select the correct rail
- Dual-rail payment engine:
  - **\*99# (USSD)** — used when supported by the carrier
  - **UPI 123PAY (IVR)** — automatic fallback, used for Jio and any 4G-only connection where USSD isn't available
- Biometric confirmation gate before every payment is triggered
- Auto-dial — the constructed USSD/IVR string is triggered automatically, no manual typing
- Call-end detection — automatically returns the user to the app the moment the OS-level call finishes
- Branded payment confirmation screen with animation and sound cue

### 3.3 Pay Friends
- Send money directly to a contact via UPI ID, phone number, or QR
- Works through the same offline-capable dual-rail engine as merchant payments

### 3.4 Balance & Transaction History
- Check linked account balance from within the app
- Full transaction history — offline and online payments alike, with status (success, pending, failed)
- Filter/search past transactions

### 3.5 Bill Splitting

**Core Expense Mechanics**
- Equal Splits — divide a bill evenly across all group members
- Unequal Splits — split by exact individual currency amounts
- Percentage Splits — divide costs using custom percentage distributions
- Share Splits — distribute costs using fractional ratios
- Itemized Splits — assign specific receipt line items to individuals
- Multi-Payer Support — record a single expense funded by multiple people

**Group & Contact Administration**
- Trip/House Groups — for roommates or travel itineraries
- 1-on-1 Tracking — casual expense logging outside formal groups
- Contact Syncing — import phone contacts via number or email
- Member Permissions — any group member can add/edit bills

**Debt Optimization & Settlement**
- Simplify Debts — reorganize group debts to minimize the number of transactions needed
- Settle Up Log — record cash, check, or external bank settlements
- In-app settlement via the app's own offline-capable dual-rail payment engine

**Global & Financial Tools**
- Multi-Currency Support — log bills in multiple currencies
- Live Exchange Conversion — convert foreign bills using real-time rates
- Tax/Tip Calculator — automatically distribute shared fees proportionally

**Data Management & Insights**
- Receipt Storage — attach receipt images to individual expense logs
- OCR Scanning — extract text from receipt photos for itemization
- Spending Analytics — charts categorized by spending type
- Global Search — search history by merchant, note, or amount
- Data Export — download group ledgers as CSV

**System & Interface**
- Default Split Setup — save custom splitting ratios for fast logging
- Push Notifications — alerts for new edits, splits, or payment updates
- Cross-Platform Sync — keep data synchronized across devices

### 3.6 Pending Requests
- Send and receive payment requests from friends/contacts
- Accept, decline, or pay a pending request directly from the request screen
- Notifications for new incoming requests

### 3.7 Autopay Management
- Set up recurring/scheduled payments to a person or biller
- View, edit, and cancel active autopay mandates
- Manage autopay limits and frequency

### 3.8 UI/UX
- Modern, high-energy visual identity aimed at a young/Gen-Z audience
- Smooth animations and sound cues throughout, especially around payment confirmation
- Floating scan button accessible from anywhere in the app (primary action, always reachable)
- Minimal, clean handling of the unavoidable OS-level dialer moment during offline payments — pre-filled fields, fast auto-return, so the disruption is as brief as possible

---

## 4. App Behavior — End-to-End Flow

1. User opens app → logs in via phone number + OTP
2. Home screen shows balance, quick actions (Pay Friends, Scan & Pay, Split, Requests, History), and the floating scan button
3. User taps scan → camera opens → scans a QR code
4. App decodes VPA + amount locally
5. App detects the user's carrier/network condition in the background
6. App selects the correct rail automatically — \*99# or 123PAY IVR — and constructs the dial string with all details pre-filled
7. User confirms via biometric (face) authentication
8. App auto-triggers the call; the OS-level dialer briefly appears
9. User completes only the unavoidable step — entering their UPI PIN when prompted
10. App detects the call ending and automatically returns the user to the app
11. Confirmation screen shows the successful payment with animation/sound
12. Transaction is logged into history and reflected in balance
13. For split expenses: settling up follows the same steps 3–12, initiated from the Split screen instead of the scan button
14. For requests: accepting a pending request routes into the same payment flow
15. For autopay: scheduled payments run automatically at their set time, following the same rail-selection and confirmation logic, with a notification sent to the user

---

## 5. Technical Architecture

### Stack
| Layer | Choice |
|---|---|
| Language | Kotlin |
| UI | Jetpack Compose |
| QR Scanning | CameraX + ML Kit Barcode Scanning |
| Biometric Auth | Android BiometricPrompt API |
| Call Trigger | `Intent.ACTION_CALL` |
| Call-End Detection | `PhoneStateListener` / `TelephonyManager` |
| Carrier Detection | `TelephonyManager.getSimOperatorName()` |
| Phone Login/OTP | Twilio Verify API |
| Architecture Pattern | MVVM (ViewModel + StateFlow) |
| Backend | Lightweight service for user accounts, transaction history, split/group data, autopay scheduling, pending requests, receipt storage, and analytics |
| Payment Rails | \*99# (primary), UPI 123PAY IVR (automatic fallback, especially for Jio) |
| Receipt OCR | ML Kit Text Recognition |
| Currency Conversion | Real-time exchange rate API |

### Permissions Required
- `CALL_PHONE` — to auto-dial \*99#/123PAY IVR
- `CAMERA` — QR scanning
- `USE_BIOMETRIC` — face authentication
- `READ_PHONE_STATE` — carrier detection and call-end detection

---

## 6. Demo Plan

- Primary demo on the team's own pre-setup phone with a linked account, executing a real transaction to a teammate
- Demonstrate the Jio fallback specifically — show the app auto-detecting the carrier and routing through 123PAY IVR instead of failing
- Optional: invite a judge to try it live on their own phone as a secondary moment
- Backup: pre-recorded demo video in case of live network or stage issues