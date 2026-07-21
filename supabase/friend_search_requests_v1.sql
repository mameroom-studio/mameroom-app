-- Mameroom friend search and requests v1. Safe, additive migration.
create extension if not exists pg_trgm with schema extensions;

create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  nickname text not null check (char_length(trim(nickname)) between 2 and 30),
  friend_code text not null,
  avatar_key text,
  level integer not null default 1 check (level between 1 and 999),
  status_message text not null default '',
  room_visibility text not null default 'friends'
    check (room_visibility in ('public', 'friends', 'private')),
  account_status text not null default 'active'
    check (account_status in ('active', 'inactive', 'deleted')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index if not exists profiles_friend_code_uq
  on public.profiles (lower(friend_code));
create index if not exists profiles_nickname_search_idx
  on public.profiles using gin (lower(nickname) extensions.gin_trgm_ops)
  where account_status = 'active';

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  user_low_id uuid generated always as (least(requester_id, receiver_id)) stored,
  user_high_id uuid generated always as (greatest(requester_id, receiver_id)) stored,
  status text not null default 'pending'
    check (status in ('pending', 'accepted', 'rejected', 'expired', 'cancelled')),
  idempotency_key uuid not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  responded_at timestamptz,
  expires_at timestamptz not null default (now() + interval '14 days'),
  cancelled_at timestamptz,
  rejected_at timestamptz,
  check (requester_id <> receiver_id),
  unique (requester_id, idempotency_key)
);
create unique index if not exists friend_requests_one_pending_pair_uq
  on public.friend_requests (user_low_id, user_high_id) where status = 'pending';
create index if not exists friend_requests_participant_idx
  on public.friend_requests (requester_id, receiver_id, status, updated_at desc);

create table if not exists public.friendships (
  id uuid primary key default gen_random_uuid(),
  user_low_id uuid not null references public.profiles(id) on delete cascade,
  user_high_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  check (user_low_id < user_high_id),
  unique (user_low_id, user_high_id)
);

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);

alter table public.profiles enable row level security;
alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.user_blocks enable row level security;

drop policy if exists "Users can read own profile" on public.profiles;
create policy "Users can read own profile" on public.profiles for select
  to authenticated using (id = auth.uid());
drop policy if exists "Users can update own profile" on public.profiles;
create policy "Users can update own profile" on public.profiles for update
  to authenticated using (id = auth.uid()) with check (id = auth.uid());
drop policy if exists "Participants can read friend requests" on public.friend_requests;
create policy "Participants can read friend requests" on public.friend_requests for select
  to authenticated using (auth.uid() in (requester_id, receiver_id));
drop policy if exists "Participants can read friendships" on public.friendships;
create policy "Participants can read friendships" on public.friendships for select
  to authenticated using (auth.uid() in (user_low_id, user_high_id));
drop policy if exists "Blockers can read own blocks" on public.user_blocks;
create policy "Blockers can read own blocks" on public.user_blocks for select
  to authenticated using (blocker_id = auth.uid());

revoke all on public.profiles, public.friend_requests, public.friendships, public.user_blocks from anon;
revoke insert, delete on public.profiles from authenticated;
revoke insert, update, delete on public.friend_requests, public.friendships, public.user_blocks from authenticated;

create or replace function public.search_friend_profiles(
  p_query text, p_limit integer default 20, p_cursor uuid default null
) returns table (
  user_id uuid, nickname text, friend_code text, avatar_key text, level integer,
  status_message text, room_visibility text, relationship_state text,
  request_id uuid, requested_at timestamptz
) language plpgsql security definer set search_path = public, pg_temp as $$
declare v_user uuid := auth.uid(); v_query text := lower(trim(p_query));
begin
  if v_user is null then raise exception using errcode = '42501', message = 'authentication_required'; end if;
  if char_length(v_query) < 2 then raise exception using errcode = '22023', message = 'query_too_short'; end if;
  p_limit := least(greatest(coalesce(p_limit, 20), 1), 50);
  return query
  select p.id, p.nickname, p.friend_code, p.avatar_key, p.level, p.status_message,
    p.room_visibility,
    case
      when p.id = v_user then 'self'
      when bm.blocker_id is not null then 'blockedByMe'
      when bt.blocker_id is not null then 'blockedMe'
      when f.id is not null then 'accepted'
      when r.status = 'pending' and r.requester_id = v_user then 'outgoingPending'
      when r.status = 'pending' then 'incomingPending'
      when r.status = 'rejected' then 'rejected'
      when r.status = 'expired' or (r.status = 'pending' and r.expires_at <= now()) then 'expired'
      when r.status = 'cancelled' then 'cancelled'
      else 'none' end,
    r.id, r.created_at
  from public.profiles p
  left join public.user_blocks bm on bm.blocker_id = v_user and bm.blocked_id = p.id
  left join public.user_blocks bt on bt.blocker_id = p.id and bt.blocked_id = v_user
  left join public.friendships f on f.user_low_id = least(v_user,p.id) and f.user_high_id = greatest(v_user,p.id)
  left join lateral (
    select fr.* from public.friend_requests fr
    where fr.user_low_id = least(v_user,p.id) and fr.user_high_id = greatest(v_user,p.id)
    order by fr.created_at desc limit 1
  ) r on true
  where p.account_status = 'active' and (p_cursor is null or p.id > p_cursor)
    and (lower(p.nickname) % v_query or lower(p.friend_code) = v_query)
  order by p.id limit p_limit;
end $$;

create or replace function public.list_friend_profiles(p_kind text default 'friends')
returns table (user_id uuid, nickname text, friend_code text, avatar_key text, level integer,
status_message text, room_visibility text, relationship_state text, request_id uuid, requested_at timestamptz)
language plpgsql security definer set search_path = public, pg_temp as $$
declare v_user uuid := auth.uid();
begin
 if v_user is null then raise exception using errcode='42501', message='authentication_required'; end if;
 if p_kind not in ('friends','incoming','recommended') then raise exception using errcode='22023', message='invalid_list_kind'; end if;
 return query
 with candidates as (
  select case when f.user_low_id=v_user then f.user_high_id else f.user_low_id end other_id,
   'accepted'::text relation, null::uuid rid, f.created_at stamp from public.friendships f
   where v_user in (f.user_low_id,f.user_high_id) and p_kind='friends'
  union all select r.requester_id,'incomingPending',r.id,r.created_at from public.friend_requests r
   where r.receiver_id=v_user and r.status='pending' and r.expires_at>now() and p_kind='incoming'
  union all select p.id,'none',null::uuid,null::timestamptz from public.profiles p where p_kind='recommended'
   and p.id<>v_user and p.account_status='active'
   and not exists(select 1 from public.friendships f where f.user_low_id=least(v_user,p.id) and f.user_high_id=greatest(v_user,p.id))
   and not exists(select 1 from public.user_blocks b where (b.blocker_id=v_user and b.blocked_id=p.id) or (b.blocker_id=p.id and b.blocked_id=v_user))
 )
 select p.id,p.nickname,p.friend_code,p.avatar_key,p.level,p.status_message,p.room_visibility,
  c.relation,c.rid,c.stamp from candidates c join public.profiles p on p.id=c.other_id
 where p.account_status='active' order by c.stamp desc nulls last limit 50;
end $$;

create or replace function public.send_friend_request(p_receiver_id uuid, p_idempotency_key uuid)
returns uuid language plpgsql security definer set search_path = public, pg_temp as $$
declare v_user uuid := auth.uid(); v_id uuid; v_existing public.friend_requests;
begin
  if v_user is null then raise exception using errcode='42501', message='authentication_required'; end if;
  if v_user = p_receiver_id then raise exception using errcode='22023', message='self_request'; end if;
  if not exists(select 1 from public.profiles where id=p_receiver_id and account_status='active') then
    raise exception using errcode='P0002', message='user_unavailable'; end if;
  if exists(select 1 from public.user_blocks where (blocker_id=v_user and blocked_id=p_receiver_id) or (blocker_id=p_receiver_id and blocked_id=v_user)) then
    raise exception using errcode='42501', message='blocked_relationship'; end if;
  if exists(select 1 from public.friendships where user_low_id=least(v_user,p_receiver_id) and user_high_id=greatest(v_user,p_receiver_id)) then
    raise exception using errcode='23505', message='already_friends'; end if;
  select * into v_existing from public.friend_requests
    where user_low_id=least(v_user,p_receiver_id) and user_high_id=greatest(v_user,p_receiver_id)
      and status='pending' for update;
  if found then
    if v_existing.requester_id=p_receiver_id then raise exception using errcode='23505', message='incoming_request_exists'; end if;
    return v_existing.id;
  end if;
  select id into v_id from public.friend_requests where requester_id=v_user and idempotency_key=p_idempotency_key;
  if v_id is not null then return v_id; end if;
  insert into public.friend_requests(requester_id,receiver_id,idempotency_key)
    values(v_user,p_receiver_id,p_idempotency_key) returning id into v_id;
  return v_id;
exception when unique_violation then
  select id into v_id from public.friend_requests where user_low_id=least(v_user,p_receiver_id)
    and user_high_id=greatest(v_user,p_receiver_id) and status='pending';
  if v_id is not null then return v_id; end if; raise;
end $$;

create or replace function public.respond_friend_request(p_request_id uuid, p_accept boolean)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
declare v_user uuid := auth.uid(); r public.friend_requests;
begin
  select * into r from public.friend_requests where id=p_request_id for update;
  if r.id is null then raise exception using errcode='P0002', message='request_not_found'; end if;
  if r.receiver_id<>v_user then raise exception using errcode='42501', message='receiver_only'; end if;
  if r.status<>'pending' then raise exception using errcode='23514', message='invalid_transition'; end if;
  if r.expires_at<=now() then update public.friend_requests set status='expired',updated_at=now() where id=r.id;
    raise exception using errcode='23514', message='request_expired'; end if;
  if exists(select 1 from public.user_blocks where (blocker_id=r.requester_id and blocked_id=r.receiver_id) or (blocker_id=r.receiver_id and blocked_id=r.requester_id)) then
    raise exception using errcode='42501', message='blocked_relationship'; end if;
  if p_accept then
    insert into public.friendships(user_low_id,user_high_id) values(least(r.requester_id,r.receiver_id),greatest(r.requester_id,r.receiver_id)) on conflict do nothing;
    update public.friend_requests set status='accepted',responded_at=now(),updated_at=now() where id=r.id;
  else
    update public.friend_requests set status='rejected',rejected_at=now(),responded_at=now(),updated_at=now() where id=r.id;
  end if;
end $$;

create or replace function public.cancel_friend_request(p_request_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  update public.friend_requests set status='cancelled',cancelled_at=now(),updated_at=now()
  where id=p_request_id and requester_id=auth.uid() and status='pending';
  if not found then raise exception using errcode='23514', message='invalid_transition'; end if;
end $$;

create or replace function public.remove_friend(p_friend_id uuid)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  delete from public.friendships where user_low_id=least(auth.uid(),p_friend_id)
    and user_high_id=greatest(auth.uid(),p_friend_id);
end $$;

create or replace function public.set_user_block(p_user_id uuid, p_blocked boolean)
returns void language plpgsql security definer set search_path = public, pg_temp as $$
begin
  if auth.uid() is null or auth.uid()=p_user_id then raise exception using errcode='22023', message='invalid_user'; end if;
  if p_blocked then
    insert into public.user_blocks(blocker_id,blocked_id) values(auth.uid(),p_user_id) on conflict do nothing;
    delete from public.friendships where user_low_id=least(auth.uid(),p_user_id) and user_high_id=greatest(auth.uid(),p_user_id);
    update public.friend_requests set status='cancelled',cancelled_at=now(),updated_at=now()
      where user_low_id=least(auth.uid(),p_user_id) and user_high_id=greatest(auth.uid(),p_user_id) and status='pending';
  else delete from public.user_blocks where blocker_id=auth.uid() and blocked_id=p_user_id; end if;
end $$;

revoke all on function public.search_friend_profiles(text,integer,uuid) from public;
revoke all on function public.list_friend_profiles(text) from public;
revoke all on function public.send_friend_request(uuid,uuid) from public;
revoke all on function public.respond_friend_request(uuid,boolean) from public;
revoke all on function public.cancel_friend_request(uuid) from public;
revoke all on function public.remove_friend(uuid) from public;
revoke all on function public.set_user_block(uuid,boolean) from public;
grant execute on function public.search_friend_profiles(text,integer,uuid) to authenticated;
grant execute on function public.list_friend_profiles(text) to authenticated;
grant execute on function public.send_friend_request(uuid,uuid) to authenticated;
grant execute on function public.respond_friend_request(uuid,boolean) to authenticated;
grant execute on function public.cancel_friend_request(uuid) to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.set_user_block(uuid,boolean) to authenticated;

