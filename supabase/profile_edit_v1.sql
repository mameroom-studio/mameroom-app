-- Mameroom Edit Profile v1.
-- Additive and fail-closed: no existing profile, character, shop, inventory,
-- memory seed, or achievement ownership data is deleted or rewritten.
begin;

do $$
declare
  v_missing text[];
begin
  select array_agg(name) into v_missing
  from (values ('profiles'), ('memory_seeds'), ('user_badges'),
               ('badge_definitions'), ('friendships')) expected(name)
  where to_regclass('public.' || name) is null;
  if v_missing is not null then
    raise exception 'profile_edit_v1 preflight failed; missing tables: %', v_missing;
  end if;

  if not exists (select 1 from information_schema.columns
    where table_schema='public' and table_name='profiles'
      and column_name='nickname' and data_type='text')
    or not exists (select 1 from information_schema.columns
      where table_schema='public' and table_name='memory_seeds'
      and column_name='user_id' and data_type='uuid')
    or not exists (select 1 from information_schema.columns
      where table_schema='public' and table_name='user_badges'
      and column_name='user_id' and data_type='uuid') then
    raise exception 'profile_edit_v1 preflight failed; deployed schema differs from v1 contract';
  end if;
end $$;

alter table public.user_badges add column if not exists id uuid;
update public.user_badges set id = gen_random_uuid() where id is null;
alter table public.user_badges alter column id set default gen_random_uuid();
alter table public.user_badges alter column id set not null;
create unique index if not exists user_badges_id_uq on public.user_badges(id);

alter table public.profiles
  add column if not exists bio text not null default '',
  add column if not exists today_goal text not null default '',
  add column if not exists featured_memory_seed_id uuid,
  add column if not exists featured_user_badge_id uuid;

do $$
begin
  if not exists (select 1 from pg_constraint
    where conrelid='public.profiles'::regclass
      and conname='profiles_featured_memory_seed_id_fkey') then
    alter table public.profiles add constraint profiles_featured_memory_seed_id_fkey
      foreign key(featured_memory_seed_id) references public.memory_seeds(id)
      on delete set null;
  end if;
  if not exists (select 1 from pg_constraint
    where conrelid='public.profiles'::regclass
      and conname='profiles_featured_user_badge_id_fkey') then
    alter table public.profiles add constraint profiles_featured_user_badge_id_fkey
      foreign key(featured_user_badge_id) references public.user_badges(id)
      on delete set null;
  end if;
end $$;

create index if not exists profiles_featured_memory_seed_idx
  on public.profiles(featured_memory_seed_id)
  where featured_memory_seed_id is not null;
create index if not exists profiles_featured_user_badge_idx
  on public.profiles(featured_user_badge_id)
  where featured_user_badge_id is not null;
create index if not exists user_badges_user_id_idx
  on public.user_badges(user_id, id);

-- Never alter existing 21-30 character nicknames. New duplicates make this
-- migration abort instead of silently modifying production data.
do $$
begin
  if exists (
    select lower(btrim(nickname)) from public.profiles
    group by lower(btrim(nickname)) having count(*) > 1
  ) then
    raise exception 'profile_edit_v1 preflight failed; normalized nickname duplicates exist';
  end if;
end $$;
create unique index if not exists profiles_normalized_nickname_uq
  on public.profiles(lower(btrim(nickname)));

create or replace function public.get_my_edit_profile()
returns jsonb language sql security definer set search_path=public,pg_temp
as $$
  select case when auth.uid() is null then null else jsonb_build_object(
    'profile', (select jsonb_build_object(
      'nickname',p.nickname,'bio',p.bio,'today_goal',p.today_goal,
      'avatar_key',p.avatar_key,'updated_at',p.updated_at,
      'featured_memory_seed_id',p.featured_memory_seed_id,
      'featured_user_badge_id',p.featured_user_badge_id)
      from profiles p where p.id=auth.uid()),
    'trees', coalesce((select jsonb_agg(jsonb_build_object(
      'id',m.id,'seed_type',m.seed_type,'growth_stage',m.growth_stage,
      'asset_key',m.asset_key,'completed_at',m.completed_at)
      order by m.completed_at desc nulls last)
      from memory_seeds m where m.user_id=auth.uid()
        and m.status='completed' and m.growth_stage='complete'),'[]'::jsonb),
    'badges', coalesce((select jsonb_agg(jsonb_build_object(
      'id',ub.id,'badge_id',b.id,'code',b.code,'name',b.name,
      'description',b.description,'grade',b.grade,'asset_path',b.asset_path,
      'unlocked_at',ub.unlocked_at) order by ub.unlocked_at desc)
      from user_badges ub join badge_definitions b on b.id=ub.badge_id
      where ub.user_id=auth.uid() and b.is_active),'[]'::jsonb)
  ) end
$$;

create or replace function public.update_my_profile(
  p_nickname text, p_bio text, p_today_goal text,
  p_featured_memory_seed_id uuid default null,
  p_featured_user_badge_id uuid default null,
  p_expected_updated_at timestamptz default null
) returns jsonb language plpgsql security definer
set search_path=public,pg_temp as $$
declare
  v_user uuid := auth.uid();
  v_nickname text := regexp_replace(btrim(coalesce(p_nickname,'')), '\s+', ' ', 'g');
  v_profile profiles%rowtype;
begin
  if v_user is null then raise exception using errcode='28000', message='Authentication is required.'; end if;
  if char_length(v_nickname) not between 2 and 30 then
    raise exception using errcode='22023', message='Nickname must be 2 to 30 characters.';
  end if;
  if char_length(coalesce(p_bio,'')) > 80 or char_length(coalesce(p_today_goal,'')) > 50 then
    raise exception using errcode='22023', message='Profile text is too long.';
  end if;

  select * into v_profile from profiles where id=v_user for update;
  if not found then raise exception using errcode='P0002', message='Profile not found.'; end if;
  if p_expected_updated_at is not null and v_profile.updated_at <> p_expected_updated_at then
    raise exception using errcode='40001', message='Profile was changed on another device.';
  end if;
  if exists (select 1 from profiles where id<>v_user and lower(btrim(nickname))=lower(v_nickname)) then
    raise exception using errcode='23505', message='Nickname is already in use.';
  end if;
  if p_featured_memory_seed_id is not null and not exists (
    select 1 from memory_seeds where id=p_featured_memory_seed_id
      and user_id=v_user and status='completed' and growth_stage='complete'
  ) then raise exception using errcode='42501', message='This memory tree cannot be featured.'; end if;
  if p_featured_user_badge_id is not null and not exists (
    select 1 from user_badges ub join badge_definitions b on b.id=ub.badge_id
    where ub.id=p_featured_user_badge_id and ub.user_id=v_user and b.is_active
  ) then raise exception using errcode='42501', message='This badge cannot be featured.'; end if;

  update profiles set nickname=v_nickname, bio=btrim(coalesce(p_bio,'')),
    today_goal=btrim(coalesce(p_today_goal,'')),
    featured_memory_seed_id=p_featured_memory_seed_id,
    featured_user_badge_id=p_featured_user_badge_id, updated_at=now()
  where id=v_user;
  return get_my_edit_profile();
end $$;

create or replace function public.get_friend_profile(p_friend_id uuid)
returns jsonb language plpgsql security definer
set search_path=public,pg_temp as $$
declare v_user uuid:=auth.uid(); v_result jsonb;
begin
  if v_user is null or p_friend_id is null or p_friend_id=v_user then return null; end if;
  if not exists (select 1 from friendships f
    where f.user_low_id=least(v_user,p_friend_id)
      and f.user_high_id=greatest(v_user,p_friend_id))
    or exists (select 1 from user_blocks b
      where (b.blocker_id=v_user and b.blocked_id=p_friend_id)
         or (b.blocker_id=p_friend_id and b.blocked_id=v_user)) then return null;
  end if;
  select jsonb_build_object(
    'id',p.id,'nickname',p.nickname,'avatar_key',p.avatar_key,
    'bio',p.bio,'today_goal',p.today_goal,
    'featured_tree',case when m.id is null then null else jsonb_build_object(
      'id',m.id,'seed_type',m.seed_type,'growth_stage',m.growth_stage,'asset_key',m.asset_key) end,
    'featured_badge',case when ub.id is null then null else jsonb_build_object(
      'id',ub.id,'name',bd.name,'description',bd.description,'grade',bd.grade,'asset_path',bd.asset_path) end)
  into v_result from profiles p
  left join memory_seeds m on m.id=p.featured_memory_seed_id
    and m.user_id=p.id and m.status='completed' and m.growth_stage='complete'
  left join user_badges ub on ub.id=p.featured_user_badge_id and ub.user_id=p.id
  left join badge_definitions bd on bd.id=ub.badge_id and bd.is_active
  where p.id=p_friend_id and p.account_status='active';
  return v_result;
end $$;

revoke all on function public.get_my_edit_profile() from public;
revoke all on function public.update_my_profile(text,text,text,uuid,uuid,timestamptz) from public;
revoke all on function public.get_friend_profile(uuid) from public;
grant execute on function public.get_my_edit_profile() to authenticated;
grant execute on function public.update_my_profile(text,text,text,uuid,uuid,timestamptz) to authenticated;
grant execute on function public.get_friend_profile(uuid) to authenticated;

-- Profile edits are now atomic RPC-only. Existing self SELECT remains intact.
drop policy if exists "Users can update own profile" on public.profiles;
revoke update on public.profiles from authenticated;
revoke all on public.profiles from anon;

commit;
