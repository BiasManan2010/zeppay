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
drop policy if exists "user_cards_read" on public.user_cards;
create policy "user_cards_read" on public.user_cards for select using (true);
drop policy if exists "user_cards_insert" on public.user_cards;
create policy "user_cards_insert" on public.user_cards for insert with check (true);
drop policy if exists "user_cards_update" on public.user_cards;
create policy "user_cards_update" on public.user_cards for update using (true);

-- Allow Flutter to resolve app_users.id from phone hash (census table).
drop policy if exists "app_users_id_lookup" on public.app_users;
create policy "app_users_id_lookup" on public.app_users for select using (true);

-- Extra unclaimed NFC tags for card assignment demos (idempotent).
insert into public.nfc_tags (nfc_id, chip_id, batch_id, assigned_at, status)
values
  ('NFC004', 'CHIP001', 'BATCH45', '2026-08-10T10:00:00Z', 'active'),
  ('NFC005', 'CHIP001', 'BATCH45', '2026-08-12T10:00:00Z', 'active')
on conflict (nfc_id) do nothing;
