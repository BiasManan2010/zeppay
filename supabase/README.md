# Supabase for Zep Pay

Two tables. No names, UPI IDs, bank details, or balances.

| Table | What it stores |
|---|---|
| `app_users` | One hashed phone per account + timestamps. Use this for **how many users**. |
| `otp_logins` | E.164 **phone** and **SHA-256 of the OTP** for Twilio login. Consumed or expired. |

The raw 6-digit code is never written. The service role key stays on `backend/server.js`.

## Setup

1. Create a project at [supabase.com](https://supabase.com)
2. SQL Editor → paste `schema.sql` → Run
3. Settings → API: copy Project URL and `service_role` key
4. On the proxy host:

```
export SUPABASE_URL=https://YOUR_PROJECT.supabase.co
export SUPABASE_SERVICE_ROLE_KEY=eyJ...
node server.js
```

`GET /stats/users` returns `{ "users": 12 }`.
`GET /health` includes `users` and `supabase: true`.
