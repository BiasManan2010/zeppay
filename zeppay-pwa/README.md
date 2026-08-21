# Zep Pay PWA (React)

Lightweight prepare-and-handoff UPI PWA — separate from the Flutter app in the repo root.

## Dev

```bash
cd zeppay-pwa
npm install
npm run dev
```

## Build

```bash
npm run build
npm run preview
```

Deploy `dist/` to Vercel or GitHub Pages.

## v1 scope

- Home → Recipient → Amount → Confirm → `upi://` handoff
- Local recents + history in `localStorage`
- No PIN, no USSD, no backend
