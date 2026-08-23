-- Zep Pay full Supabase setup (run once in SQL Editor)
-- Order: census → semiconductors → app_config → referrals → user_cards

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

-- Challenge 2: semiconductor shortage tracking (demo seed data).
-- Run in the same Supabase project as supabase/schema.sql (SQL Editor → Run).
-- Flutter app uses the anon key — never embed the service role key.

create table if not exists public.suppliers (
  supplier_id text primary key,
  name text not null,
  country text not null,
  lead_time_days integer not null,
  reliability_pct numeric not null
);

create table if not exists public.semiconductors (
  chip_id text primary key,
  part_number text not null,
  manufacturer text not null,
  category text not null,
  quantity integer not null default 0,
  minimum_stock integer not null,
  supplier_id text not null references public.suppliers (supplier_id),
  batch_id text not null,
  location text not null,
  risk_level text not null default 'INSUFFICIENT_DATA'
);

create table if not exists public.nfc_tags (
  nfc_id text primary key,
  chip_id text not null references public.semiconductors (chip_id),
  batch_id text not null,
  assigned_at timestamptz not null default now(),
  status text not null default 'active'
);

create table if not exists public.inventory_transactions (
  txn_id uuid primary key default gen_random_uuid(),
  chip_id text not null references public.semiconductors (chip_id),
  type text not null check (type in ('received', 'used', 'transferred')),
  quantity_delta integer not null,
  timestamp timestamptz not null default now()
);

create table if not exists public.alternatives (
  chip_id text not null references public.semiconductors (chip_id),
  alternative_chip_id text not null references public.semiconductors (chip_id),
  compatibility_note text not null,
  primary key (chip_id, alternative_chip_id)
);

create index if not exists inventory_transactions_chip_idx
  on public.inventory_transactions (chip_id, timestamp desc);

alter table public.suppliers enable row level security;
alter table public.semiconductors enable row level security;
alter table public.nfc_tags enable row level security;
alter table public.inventory_transactions enable row level security;
alter table public.alternatives enable row level security;

create policy "semiconductor_read" on public.suppliers for select using (true);
create policy "semiconductor_read" on public.semiconductors for select using (true);
create policy "semiconductor_read" on public.nfc_tags for select using (true);
create policy "semiconductor_read" on public.inventory_transactions for select using (true);
create policy "semiconductor_read" on public.alternatives for select using (true);

create policy "semiconductor_insert_txn" on public.inventory_transactions
  for insert with check (true);
create policy "semiconductor_update_chip" on public.semiconductors
  for update using (true);

-- Demo seed (idempotent — skips if CHIP001 already exists)
insert into public.suppliers (supplier_id, name, country, lead_time_days, reliability_pct)
values
  ('SUP12', 'DigiKey', 'USA', 21, 97.5),
  ('SUP21', 'LCSC', 'China', 14, 92.0),
  ('SUP34', 'Mouser', 'USA', 18, 96.0)
on conflict (supplier_id) do nothing;

insert into public.semiconductors (
  chip_id, part_number, manufacturer, category, quantity, minimum_stock,
  supplier_id, batch_id, location, risk_level
)
values
  ('CHIP001', 'NTAG213', 'NXP', 'NFC tag IC', 0, 500, 'SUP12', 'BATCH45', 'Zep Pay assembly — Pune', 'LOW'),
  ('CHIP002', 'STM32F103C8T6', 'ST', 'Microcontroller', 0, 120, 'SUP34', 'BATCH46', 'Prototype bench', 'LOW'),
  ('CHIP003', 'ESP32-WROOM-32', 'Espressif', 'Wi-Fi module', 0, 80, 'SUP21', 'BATCH47', 'IoT demo shelf', 'LOW'),
  ('CHIP004', 'AMS1117-3.3', 'AMS', 'LDO regulator', 0, 300, 'SUP21', 'BATCH48', 'SMT rack A2', 'LOW'),
  ('CHIP005', 'TP4056', 'NanJing Top Power', 'Li-ion charger IC', 0, 200, 'SUP21', 'BATCH49', 'Power bin', 'LOW'),
  ('CHIP006', 'CH340G', 'WCH', 'USB-UART bridge', 0, 150, 'SUP12', 'BATCH50', 'Dev kit drawer', 'INSUFFICIENT_DATA'),
  ('CHIP007', 'ATmega328P', 'Microchip', 'Microcontroller', 0, 100, 'SUP34', 'BATCH51', 'Legacy stock', 'LOW')
on conflict (chip_id) do nothing;

insert into public.nfc_tags (nfc_id, chip_id, batch_id, assigned_at, status)
values
  ('NFC001', 'CHIP001', 'BATCH45', '2026-07-01T10:00:00Z', 'active'),
  ('NFC002', 'CHIP002', 'BATCH46', '2026-07-15T11:30:00Z', 'active'),
  ('NFC003', 'CHIP003', 'BATCH47', '2026-08-01T09:00:00Z', 'active')
on conflict (nfc_id) do nothing;

insert into public.alternatives (chip_id, alternative_chip_id, compatibility_note)
values
  ('CHIP001', 'CHIP002', 'Not pin-compatible — PCB respin required if NFC batch is delayed.'),
  ('CHIP003', 'CHIP002', 'Different footprint — firmware port needed; lower throughput.'),
  ('CHIP004', 'CHIP005', 'Different function — charger sub-board only, not main 3.3V rail.')
on conflict do nothing;

-- ~30 days of demo ledger rows (quantity_delta: + received, − used/transferred)
insert into public.inventory_transactions (chip_id, type, quantity_delta, timestamp)
select * from (values
  ('CHIP001', 'received', 1200, now() - interval '28 days'),
  ('CHIP001', 'used', -45, now() - interval '27 days'),
  ('CHIP001', 'used', -52, now() - interval '24 days'),
  ('CHIP001', 'used', -48, now() - interval '21 days'),
  ('CHIP001', 'used', -55, now() - interval '18 days'),
  ('CHIP001', 'used', -50, now() - interval '15 days'),
  ('CHIP001', 'used', -47, now() - interval '12 days'),
  ('CHIP001', 'used', -53, now() - interval '9 days'),
  ('CHIP001', 'used', -49, now() - interval '6 days'),
  ('CHIP001', 'used', -51, now() - interval '3 days'),
  ('CHIP001', 'used', -46, now() - interval '1 day'),
  ('CHIP001', 'transferred', -30, now() - interval '5 days'),
  ('CHIP002', 'received', 400, now() - interval '29 days'),
  ('CHIP002', 'used', -8, now() - interval '28 days'),
  ('CHIP002', 'used', -8, now() - interval '24 days'),
  ('CHIP002', 'used', -8, now() - interval '20 days'),
  ('CHIP002', 'used', -8, now() - interval '16 days'),
  ('CHIP002', 'used', -8, now() - interval '12 days'),
  ('CHIP002', 'used', -8, now() - interval '8 days'),
  ('CHIP002', 'used', -8, now() - interval '4 days'),
  ('CHIP003', 'received', 250, now() - interval '30 days'),
  ('CHIP003', 'used', -5, now() - interval '25 days'),
  ('CHIP003', 'used', -5, now() - interval '20 days'),
  ('CHIP003', 'used', -5, now() - interval '15 days'),
  ('CHIP003', 'used', -5, now() - interval '10 days'),
  ('CHIP003', 'used', -5, now() - interval '5 days'),
  ('CHIP004', 'received', 2000, now() - interval '30 days'),
  ('CHIP004', 'used', -120, now() - interval '20 days'),
  ('CHIP004', 'used', -90, now() - interval '10 days'),
  ('CHIP005', 'received', 600, now() - interval '28 days'),
  ('CHIP005', 'used', -25, now() - interval '14 days'),
  ('CHIP005', 'used', -22, now() - interval '7 days'),
  ('CHIP006', 'received', 300, now() - interval '25 days'),
  ('CHIP006', 'used', -5, now() - interval '20 days'),
  ('CHIP007', 'received', 350, now() - interval '27 days'),
  ('CHIP007', 'used', -6, now() - interval '26 days'),
  ('CHIP007', 'used', -6, now() - interval '23 days'),
  ('CHIP007', 'used', -6, now() - interval '20 days'),
  ('CHIP007', 'used', -6, now() - interval '17 days'),
  ('CHIP007', 'used', -6, now() - interval '14 days'),
  ('CHIP007', 'used', -6, now() - interval '11 days'),
  ('CHIP007', 'used', -6, now() - interval '8 days'),
  ('CHIP007', 'used', -6, now() - interval '5 days'),
  ('CHIP007', 'used', -6, now() - interval '2 days')
) as v(chip_id, type, quantity_delta, timestamp)
where not exists (
  select 1 from public.inventory_transactions where chip_id = 'CHIP001' limit 1
);

-- Sync stored quantity + risk_level from ledger (app repeats this after each insert)
update public.semiconductors s
set quantity = coalesce((
  select sum(t.quantity_delta)::integer
  from public.inventory_transactions t
  where t.chip_id = s.chip_id
), 0);

update public.semiconductors set risk_level = 'HIGH' where chip_id = 'CHIP001';
update public.semiconductors set risk_level = 'MEDIUM' where chip_id = 'CHIP002';
update public.semiconductors set risk_level = 'LOW' where chip_id in ('CHIP003', 'CHIP004', 'CHIP005', 'CHIP007');
update public.semiconductors set risk_level = 'INSUFFICIENT_DATA' where chip_id = 'CHIP006';

-- App configuration (admin-controlled toggles). One row per key.
-- Paste in Supabase → SQL Editor after schema.sql.

create table if not exists public.app_config (
  key text primary key,
  value text not null,
  updated_at timestamptz not null default now()
);

comment on table public.app_config is
  'Remote feature flags — e.g. donations_enabled. Flip in Supabase table editor.';

insert into public.app_config (key, value)
values ('donations_enabled', 'false')
on conflict (key) do nothing;

alter table public.app_config enable row level security;

drop policy if exists "anon read app_config" on public.app_config;
create policy "anon read app_config"
  on public.app_config
  for select
  to anon
  using (true);

-- Referral fields on existing app_users (user identity — not a new table category).
-- Paste in Supabase → SQL Editor after schema.sql.

alter table public.app_users
  add column if not exists referral_code text,
  add column if not exists referred_by text;

create unique index if not exists app_users_referral_code_uidx
  on public.app_users (referral_code)
  where referral_code is not null;

create index if not exists app_users_referred_by_idx
  on public.app_users (referred_by);

comment on column public.app_users.referral_code is
  'Short shareable code for zero-cost user acquisition (local ZepCoins rewards).';
comment on column public.app_users.referred_by is
  'Referral code of the inviter, if the user joined via invite.';

create or replace function public._gen_referral_code()
returns text
language plpgsql
as $$
declare
  chars text := 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  result text := '';
  i int;
begin
  for i in 1..6 loop
    result := result || substr(chars, 1 + floor(random() * length(chars))::int, 1);
  end loop;
  return result;
end;
$$;

create or replace function public.ensure_referral_code(p_hash text)
returns text
language plpgsql
security definer
set search_path = public
as $$
declare
  code text;
  tries int := 0;
begin
  select referral_code into code from public.app_users where phone_hash = p_hash;
  if code is not null then
    return code;
  end if;
  loop
    tries := tries + 1;
    if tries > 24 then
      raise exception 'could not allocate referral code';
    end if;
    code := public._gen_referral_code();
    update public.app_users
       set referral_code = code
     where phone_hash = p_hash
       and referral_code is null;
    if found then
      return code;
    end if;
    select referral_code into code from public.app_users where phone_hash = p_hash;
    if code is not null then
      return code;
    end if;
  end loop;
end;
$$;

create or replace function public.apply_referral_code(p_hash text, p_code text)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  norm text := upper(trim(p_code));
begin
  if norm is null or length(norm) < 4 then
    return false;
  end if;
  if not exists (select 1 from public.app_users where referral_code = norm) then
    return false;
  end if;
  update public.app_users
     set referred_by = norm
   where phone_hash = p_hash
     and referred_by is null
     and referral_code is distinct from norm;
  return found;
end;
$$;

create or replace function public.referral_friend_count(p_code text)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*)::bigint
    from public.app_users
   where referred_by = upper(trim(p_code));
$$;

create or replace function public.referral_joined_hashes(p_code text)
returns setof text
language sql
stable
security definer
set search_path = public
as $$
  select phone_hash
    from public.app_users
   where referred_by = upper(trim(p_code));
$$;

grant execute on function public.ensure_referral_code(text) to anon, authenticated;
grant execute on function public.apply_referral_code(text, text) to anon, authenticated;
grant execute on function public.referral_friend_count(text) to anon, authenticated;
grant execute on function public.referral_joined_hashes(text) to anon, authenticated;

-- Zep Card ownership — links registered users to physical NFC chip batches.
-- Run after supabase/schema.sql and supabase/semiconductor_schema.sql.
-- Flutter uses the anon key; never embed the service role key.

create table if not exists public.user_cards (
  user_id uuid primary key references public.app_users (id) on delete cascade,
  nfc_id text not null unique references public.nfc_tags (nfc_id),
  card_name text not null,
  claimed_at timestamptz not null default now(),
  status text not null default 'active' check (status = 'active')
);

create index if not exists user_cards_nfc_idx on public.user_cards (nfc_id);

alter table public.user_cards enable row level security;

-- Demo / hackathon: open policies (tighten in production with auth.uid()).
create policy "user_cards_read" on public.user_cards for select using (true);
create policy "user_cards_insert" on public.user_cards for insert with check (true);
create policy "user_cards_update" on public.user_cards for update using (true);

-- Allow Flutter to resolve app_users.id from phone hash (census table).
create policy "app_users_id_lookup" on public.app_users for select using (true);

-- Extra unclaimed NFC tags for card assignment demos (idempotent).
insert into public.nfc_tags (nfc_id, chip_id, batch_id, assigned_at, status)
values
  ('NFC004', 'CHIP001', 'BATCH45', '2026-08-10T10:00:00Z', 'active'),
  ('NFC005', 'CHIP001', 'BATCH45', '2026-08-12T10:00:00Z', 'active')
on conflict (nfc_id) do nothing;
