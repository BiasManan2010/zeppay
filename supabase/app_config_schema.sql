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
