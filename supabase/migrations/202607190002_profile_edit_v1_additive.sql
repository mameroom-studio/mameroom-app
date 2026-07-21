-- Mameroom self profile edit v1.
-- Applies after 202607190001_profiles_v1_foundation.sql and before Friends v1.
-- Additive only: no existing auth/profile/memory data is deleted or rewritten.

begin;

do $preflight$
begin
  if to_regclass('public.profiles') is null then
    raise exception using
      errcode = 'P0001',
      message = 'profile_edit_v1_profiles_missing';
  end if;
  if to_regclass('public.memory_seeds') is null then
    raise exception using
      errcode = 'P0001',
      message = 'profile_edit_v1_memory_seeds_missing';
  end if;
end
$preflight$;

create table if not exists public.badge_definitions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null,
  grade text check (
    grade is null
    or grade in ('bronze', 'silver', 'gold', 'platinum', 'diamond')
  ),
  asset_path text,
  is_active boolean not null default true
);

create table if not exists public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id uuid not null references public.badge_definitions(id)
    on delete cascade,
  achievement_id uuid,
  unlocked_at timestamptz not null default now(),
  id uuid not null default gen_random_uuid(),
  primary key (user_id, badge_id),
  constraint user_badges_id_uq unique (id)
);

alter table public.profiles
  add column if not exists bio text not null default '',
  add column if not exists today_goal text not null default '',
  add column if not exists featured_memory_seed_id uuid,
  add column if not exists featured_user_badge_id uuid;

do $constraints$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_bio_length_ck'
  ) then
    alter table public.profiles
      add constraint profiles_bio_length_ck
      check (char_length(bio) <= 80);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_today_goal_length_ck'
  ) then
    alter table public.profiles
      add constraint profiles_today_goal_length_ck
      check (char_length(today_goal) <= 50);
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_featured_memory_seed_id_fkey'
  ) then
    alter table public.profiles
      add constraint profiles_featured_memory_seed_id_fkey
      foreign key (featured_memory_seed_id)
      references public.memory_seeds(id)
      on delete set null;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_featured_user_badge_id_fkey'
  ) then
    alter table public.profiles
      add constraint profiles_featured_user_badge_id_fkey
      foreign key (featured_user_badge_id)
      references public.user_badges(id)
      on delete set null;
  end if;
end
$constraints$;

create index if not exists profiles_featured_memory_seed_idx
  on public.profiles(featured_memory_seed_id)
  where featured_memory_seed_id is not null;
create index if not exists profiles_featured_user_badge_idx
  on public.profiles(featured_user_badge_id)
  where featured_user_badge_id is not null;
create index if not exists user_badges_user_unlocked_idx
  on public.user_badges(user_id, unlocked_at desc);

alter table public.badge_definitions enable row level security;
alter table public.user_badges enable row level security;

create policy "Authenticated users can read active badge definitions"
on public.badge_definitions
for select
to authenticated
using (is_active);

create policy "Users can read own earned badges"
on public.user_badges
for select
to authenticated
using (user_id = (select auth.uid()));

revoke all on table public.badge_definitions from anon;
revoke all on table public.user_badges from anon;
revoke all on table public.badge_definitions from authenticated;
revoke all on table public.user_badges from authenticated;
grant select on table public.badge_definitions to authenticated;
grant select on table public.user_badges to authenticated;

create function public.get_my_edit_profile()
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_user uuid := auth.uid();
  v_result jsonb;
begin
  if v_user is null then
    raise exception using
      errcode = '42501',
      message = 'authentication_required';
  end if;

  select jsonb_build_object(
    'profile', jsonb_build_object(
      'nickname', p.nickname,
      'bio', p.bio,
      'today_goal', p.today_goal,
      'avatar_key', p.avatar_key,
      'updated_at', p.updated_at,
      'featured_memory_seed_id', p.featured_memory_seed_id,
      'featured_user_badge_id', p.featured_user_badge_id
    ),
    'trees', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', m.id,
          'seed_type', m.seed_type,
          'growth_stage', m.growth_stage,
          'asset_key', m.asset_key,
          'completed_at', m.completed_at
        )
        order by m.completed_at desc nulls last, m.id
      )
      from public.memory_seeds m
      where m.user_id = v_user
        and m.status = 'completed'
        and m.growth_stage = 'complete'
    ), '[]'::jsonb),
    'badges', coalesce((
      select jsonb_agg(
        jsonb_build_object(
          'id', ub.id,
          'badge_id', ub.badge_id,
          'name', b.name,
          'description', b.description,
          'grade', b.grade,
          'asset_path', b.asset_path,
          'unlocked_at', ub.unlocked_at
        )
        order by ub.unlocked_at desc, ub.id
      )
      from public.user_badges ub
      join public.badge_definitions b on b.id = ub.badge_id
      where ub.user_id = v_user
        and b.is_active
    ), '[]'::jsonb)
  )
    into v_result
  from public.profiles p
  where p.id = v_user
    and p.account_status = 'active';

  if v_result is null then
    raise exception using
      errcode = 'P0002',
      message = 'profile_not_found';
  end if;

  return v_result;
end
$function$;

create function public.update_my_profile(
  p_nickname text,
  p_bio text,
  p_today_goal text,
  p_featured_memory_seed_id uuid default null,
  p_featured_user_badge_id uuid default null,
  p_expected_updated_at timestamptz default null
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_user uuid := auth.uid();
  v_nickname text := regexp_replace(
    btrim(coalesce(p_nickname, '')),
    '\s+',
    ' ',
    'g'
  );
  v_current_updated_at timestamptz;
begin
  if v_user is null then
    raise exception using
      errcode = '42501',
      message = 'authentication_required';
  end if;
  if char_length(v_nickname) not between 2 and 30 then
    raise exception using
      errcode = '22023',
      message = 'nickname_length_invalid';
  end if;
  if char_length(btrim(coalesce(p_bio, ''))) > 80 then
    raise exception using
      errcode = '22023',
      message = 'bio_length_invalid';
  end if;
  if char_length(btrim(coalesce(p_today_goal, ''))) > 50 then
    raise exception using
      errcode = '22023',
      message = 'today_goal_length_invalid';
  end if;

  select p.updated_at
    into v_current_updated_at
  from public.profiles p
  where p.id = v_user
    and p.account_status = 'active'
  for update;

  if not found then
    raise exception using
      errcode = 'P0002',
      message = 'profile_not_found';
  end if;
  if p_expected_updated_at is not null
     and v_current_updated_at <> p_expected_updated_at then
    raise exception using
      errcode = '40001',
      message = 'profile_write_conflict';
  end if;
  if exists (
    select 1
    from public.profiles p
    where p.id <> v_user
      and lower(btrim(p.nickname)) = lower(v_nickname)
  ) then
    raise exception using
      errcode = '23505',
      message = 'nickname_already_in_use';
  end if;
  if p_featured_memory_seed_id is not null
     and not exists (
       select 1
       from public.memory_seeds m
       where m.id = p_featured_memory_seed_id
         and m.user_id = v_user
         and m.status = 'completed'
         and m.growth_stage = 'complete'
     ) then
    raise exception using
      errcode = '42501',
      message = 'featured_memory_seed_not_owned_or_ineligible';
  end if;
  if p_featured_user_badge_id is not null
     and not exists (
       select 1
       from public.user_badges ub
       join public.badge_definitions b on b.id = ub.badge_id
       where ub.id = p_featured_user_badge_id
         and ub.user_id = v_user
         and b.is_active
     ) then
    raise exception using
      errcode = '42501',
      message = 'featured_badge_not_owned_or_inactive';
  end if;

  update public.profiles
  set
    nickname = v_nickname,
    bio = btrim(coalesce(p_bio, '')),
    today_goal = btrim(coalesce(p_today_goal, '')),
    featured_memory_seed_id = p_featured_memory_seed_id,
    featured_user_badge_id = p_featured_user_badge_id
  where id = v_user;

  return public.get_my_edit_profile();
end
$function$;

revoke all on function public.get_my_edit_profile() from public;
revoke all on function public.update_my_profile(
  text, text, text, uuid, uuid, timestamptz
) from public;
grant execute on function public.get_my_edit_profile() to authenticated;
grant execute on function public.update_my_profile(
  text, text, text, uuid, uuid, timestamptz
) to authenticated;

-- Profile mutation is atomic RPC-only.
revoke insert, update, delete on table public.profiles from authenticated;

commit;
