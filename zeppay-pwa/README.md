# Zep Pay — iPhone PWA

Offline-first UPI for iPhone (Add to Home Screen). **No GPay / PhonePe redirect** — payments complete in the Phone dialer via `*99#`.

## Flow

1. **Scan QR** or enter a UPI ID
2. UPI ID is **copied** to the clipboard
3. Phone opens with **`*99*1*3#`** pre-filled (send to UPI ID + amount)
4. Paste ID if asked, enter PIN in Phone
5. You **confirm** success/failure back in Zep Pay (honest ledger)

## Quick actions

- **Scan QR** — merchant / person UPI codes (camera)
- **Pay UPI ID** — type or paste `name@bank`
- **Balance** — dials `*99*3#`
- **History** — local device log only

## Dev

```bash
npm install
npm run dev
```

Build output is published to `/zeppay/ios/` on GitHub Pages.

## Limits (honest)

iOS cannot run USSD menus inside the app — the OS owns the Phone session. Zep Pay copies the ID and opens `tel:*99*1*3#`; it cannot read dialer results.
