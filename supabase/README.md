# Supabase for Zep Pay

## Census / OTP (backend)

| Table | What it stores |
|---|---|
| `app_users` | One hashed phone per account + timestamps + optional `referral_code` / `referred_by`. |
| `otp_logins` | E.164 **phone** and **SHA-256 of the OTP** for Twilio login. Consumed or expired. |
| `app_config` | Admin feature flags (e.g. `donations_enabled`). See `app_config_schema.sql`. |

The raw 6-digit code is never written. The service role key stays on `backend/server.js`.

## Semiconductor inventory (Flutter app)

Challenge 2 tables: `suppliers`, `semiconductors`, `nfc_tags`, `inventory_transactions`, `alternatives`.

The Flutter app uses the **anon** key (`SUPABASE_ANON_KEY`) — never embed the service role key.

## Setup

1. Create a project at [supabase.com](https://supabase.com)
2. SQL Editor → paste `full_setup.sql` → Run (or run each file below in order)
3. Settings → API: copy Project URL, `anon` key (Flutter), and `service_role` key (backend)
4. On the proxy host (or `backend/.env` locally):

```
export SUPABASE_URL=https://YOUR_PROJECT.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=eyJ...
node server.js
```

5. In the Flutter app Settings (or build with `--dart-define`):
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`

`GET /stats/users` returns `{ "users": 12 }`.
`GET /health` includes `users` and `supabase: true`.
