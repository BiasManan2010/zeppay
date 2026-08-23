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
