# Supabase for Zep Pay

## Census / OTP (backend)

| Table | What it stores |
|---|---|
| `app_users` | One hashed phone per account + timestamps. Use this for **how many users**. |
| `otp_logins` | E.164 **phone** and **SHA-256 of the OTP** for Twilio login. Consumed or expired. |

The raw 6-digit code is never written. The service role key stays on `backend/server.js`.

## Semiconductor inventory (Flutter app)

Challenge 2 tables: `suppliers`, `semiconductors`, `nfc_tags`, `inventory_transactions`, `alternatives`.

The Flutter app uses the **anon** key (`SUPABASE_ANON_KEY`) — never embed the service role key.

## Setup

1. Create a project at [supabase.com](https://supabase.com)
2. SQL Editor → paste `schema.sql` → Run
3. SQL Editor → paste `semiconductor_schema.sql` → Run (demo seed data)
4. Settings → API: copy Project URL and **anon** key for the app; copy `service_role` for the proxy
5. On the proxy host:

```
export SUPABASE_URL=https://YOUR_PROJECT.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=eyJ...
node server.js
```

6. In the Flutter app Settings (or build with `--dart-define`):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

`GET /stats/users` returns `{ "users": 12 }`.
`GET /health` includes `users` and `supabase: true`.
