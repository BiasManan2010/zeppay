-- Zep Pay census + Twilio login challenges.
-- Paste this in Supabase → SQL Editor → Run.
-- Use the service role key only on backend/server.js (never in the Flutter app).

create table if not exists public.app_users (
  id uuid primary key default gen_random_uuid(),
  phone_hash text not null unique,
  created_at timestamptz not null default now(),
  last_login_at timestamptz not null default now()
);

comment on table public.app_users is
  'Anonymous user census. phone_hash only — no name, UPI, bank, or raw phone.';

create table if not exists public.otp_logins (
  id uuid primary key default gen_random_uuid(),
  phone text not null,
  code_hash text not null,
  expires_at timestamptz not null,
  consumed_at timestamptz,
  created_at timestamptz not null default now()
);

comment on table public.otp_logins is
  'Twilio login: E.164 phone + SHA-256 of the OTP. Codes are hashed; rows are consumed or expire.';

create index if not exists otp_logins_phone_open_idx
  on public.otp_logins (phone)
  where consumed_at is null;

alter table public.app_users enable row level security;
alter table public.otp_logins enable row level security;

create or replace function public.app_user_count()
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::bigint from public.app_users;
$$;

create or replace function public.touch_app_user(p_hash text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.app_users (phone_hash)
  values (p_hash)
  on conflict (phone_hash) do update
    set last_login_at = now();
end;
$$;

create or replace function public.issue_otp(
  p_phone text,
  p_hash text,
  p_expires timestamptz
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.otp_logins
     set consumed_at = now()
   where phone = p_phone
     and consumed_at is null;
  insert into public.otp_logins (phone, code_hash, expires_at)
  values (p_phone, p_hash, p_expires);
end;
$$;

create or replace function public.take_otp(p_phone text, p_hash text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  rid uuid;
begin
  select id into rid
    from public.otp_logins
   where phone = p_phone
     and code_hash = p_hash
     and consumed_at is null
     and expires_at > now()
   order by created_at desc
   limit 1
   for update;
  if rid is null then
    return false;
  end if;
  update public.otp_logins set consumed_at = now() where id = rid;
  return true;
end;
$$;

revoke all on function public.issue_otp(text, text, timestamptz) from public, anon, authenticated;
revoke all on function public.take_otp(text, text) from public, anon, authenticated;
revoke all on function public.touch_app_user(text) from public, anon, authenticated;
grant execute on function public.app_user_count() to anon, authenticated, service_role;
grant execute on function public.issue_otp(text, text, timestamptz) to service_role;
grant execute on function public.take_otp(text, text) to service_role;
grant execute on function public.touch_app_user(text) to service_role;
