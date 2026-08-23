# Zep Pay — iPhone PWA

Offline-first UPI for iPhone (Add to Home Screen). **No GPay / PhonePe redirect** — payments complete in the Phone dialer via `*99#`.

## Flow

1. Scan QR or enter UPI ID + amount
2. Confirm → UPI ID copied, Phone opens with **`*99*1*3#`** pre-filled
3. Complete USSD in Phone (Zep Pay cannot read the result)
4. When you return to the app, a **single confirmation** appears instantly: “Did the payment go through?”
5. One tap records the honest outcome (success / failed / pending timeout)

## Feature parity (vs Flutter Android)

| Flutter screen | PWA | Notes |
|---|---|---|
| Scan / Pay UPI / Amount / Confirm | Yes | `*99#` via `tel:` instead of native USSD |
| Payment handoff + outcome | Yes | Page Visibility auto-return + one-tap confirm |
| History | Yes | `localStorage` on device |
| ZepCoins + Shop | Yes | Earn on confirmed payments, demo partner redeem |
| Requests (approve to pay) | Yes | Local requests list + pay flow |
| Split bill | Yes | Groups + equal split (local) |
| Spending summary | Yes | Confirmed payments only |
| Profile + receive QR | Yes | UPI ID + on-device QR pattern |
| NFC / Zep Card / Merchant | No | iOS PWA cannot write NFC tags |
| Semiconductor inventory | No | Android + Supabase feature |
| Autopay / Face confirm | No | Android-native flows |

## Dev

```bash
npm install
npm run dev
```

```bash
npm run build
```

## iOS notes

- Amount field uses `type="text"` + `inputMode="decimal"` for reliable Safari input
- Pay button shows a loading state while starting the dialer handoff
- No heuristic “success guessing” — user must confirm what happened in Phone
