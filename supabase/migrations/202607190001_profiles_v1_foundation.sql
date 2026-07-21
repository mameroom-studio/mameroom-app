-- Mameroom profiles v1 foundation.
--
-- Safety properties:
-- * additive only; no auth.users rows are updated or deleted;
-- * refuses to replace an existing public.profiles object;
-- * uses a non-PII, collision-resistant temporary nickname when metadata is
--   missing or invalid;
-- * aborts atomically when valid metadata nicknames are duplicated;
-- * creates only the profile contract required before Friends v1;
-- * keeps profile writes server-controlled.

begin;

create extension if not exists pgcrypto with schema extensions;

do $preflight$
declare
  v_duplicate_count bigint;
begin
  if to_regclass('public.profiles') is not null then
    raise exception using
      errcode = 'P0001',
      message = 'profiles_v1_existing_relation_requires_manual_review';
  end if;

  select count(*)
    into v_duplicate_count
  from (
    select lower(
      regexp_replace(
        btrim(coalesce(u.raw_user_meta_data ->> 'nickname', '')),
        '\s+',
        ' ',
        'g'
      )
    )
    from auth.users u
    group by 1
    having count(*) > 1
  ) duplicates;

  if v_duplicate_count > 0 then
    raise exception using
      errcode = 'P0001',
      message = 'profiles_v1_duplicate_auth_nicknames',
      detail = format(
        '%s normalized nickname collision group(s) exist',
        v_duplicate_count
      ),
      hint = 'Resolve collisions with the affected users before applying this migration.';
  end if;
end
$preflight$;

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null,
  friend_code text not null,
  avatar_key text,
  level integer not null default 1,
  status_message text not null default '',
  room_visibility text not null default 'friends',
  account_status text not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint profiles_nickname_length_ck
    check (char_length(btrim(nickname)) between 2 and 30),
  constraint profiles_level_range_ck
    check (level between 1 and 999),
  constraint profiles_room_visibility_ck
    check (room_visibility in ('public', 'friends', 'private')),
  constraint profiles_account_status_ck
    check (account_status in ('active', 'inactive', 'deleted'))
);

create unique index profiles_normalized_nickname_uq
  on public.profiles (lower(btrim(nickname)));
create unique index profiles_friend_code_uq
  on public.profiles (lower(friend_code));
create index profiles_active_nickname_idx
  on public.profiles (lower(nickname))
  where account_status = 'active';

create function public.profile_friend_code(p_user_id uuid)
returns text
language sql
immutable
strict
set search_path = public, extensions, pg_temp
as $function$
  select upper(substr(encode(extensions.digest(p_user_id::text, 'sha256'), 'hex'), 1, 12))
$function$;

revoke all on function public.profile_friend_code(uuid) from public;

insert into public.profiles (
  id,
  nickname,
  friend_code,
  created_at,
  updated_at
)
select
  u.id,
  case
    when char_length(
      regexp_replace(
        btrim(coalesce(u.raw_user_meta_data ->> 'nickname', '')),
        '\s+',
        ' ',
        'g'
      )
    ) between 2 and 30
    then regexp_replace(
      btrim(u.raw_user_meta_data ->> 'nickname'),
      '\s+',
      ' ',
      'g'
    )
    else '마메룸-' || upper(substr(replace(u.id::text, '-', ''), 1, 8))
  end,
  public.profile_friend_code(u.id),
  coalesce(u.created_at, now()),
  now()
from auth.users u
order by u.created_at, u.id;

create function public.set_profiles_updated_at()
returns trigger
language plpgsql
security invoker
set search_path = public, pg_temp
as $function$
begin
  new.updated_at := now();
  return new;
end
$function$;

create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_profiles_updated_at();

create function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = public, extensions, pg_temp
as $function$
declare
  v_nickname text := regexp_replace(
    btrim(coalesce(new.raw_user_meta_data ->> 'nickname', '')),
    '\s+',
    ' ',
    'g'
  );
begin
  if char_length(v_nickname) not between 2 and 30 then
    v_nickname := '마메룸-' || upper(
      substr(replace(new.id::text, '-', ''), 1, 8)
    );
  end if;

  insert into public.profiles (
    id,
    nickname,
    friend_code,
    created_at,
    updated_at
  )
  values (
    new.id,
    v_nickname,
    public.profile_friend_code(new.id),
    coalesce(new.created_at, now()),
    now()
  );

  return new;
exception
  when unique_violation then
    raise exception using
      errcode = '23505',
      message = 'profile_nickname_conflict';
end
$function$;

revoke all on function public.handle_new_auth_user_profile() from public;
revoke all on function public.set_profiles_updated_at() from public;

create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user_profile();

alter table public.profiles enable row level security;

create policy "Users can read own profile"
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));

revoke all on table public.profiles from anon;
revoke all on table public.profiles from authenticated;
grant select on table public.profiles to authenticated;

comment on table public.profiles is
  'Mameroom private profile foundation. Friend-visible fields must be exposed only through an accepted-friend RPC or restricted view.';
comment on column public.profiles.avatar_key is
  'Read-only character/avatar preview key. This column does not grant ownership or modify inventory/equipment.';

commit;
