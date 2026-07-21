-- Mameroom Friends v1 additive migration.
-- APPLY ONLY after supabase/friends_v1_preflight.sql reports a compatible
-- public.profiles contract and the target Friends objects are missing.
-- This migration intentionally does not create or alter public.profiles and
-- does not replace existing functions.

create extension if not exists pg_trgm with schema extensions;

do $guard$
declare
  v_missing text;
  v_wrong_type text;
begin
  if to_regclass('public.profiles') is null then
    raise exception using
      errcode = 'P0001',
      message = 'friends_v1_incompatible_profiles_missing';
  end if;

  select string_agg(required.name, ', ' order by required.name)
    into v_missing
  from (
    values
      ('id'), ('nickname'), ('friend_code'), ('avatar_key'), ('level'),
      ('status_message'), ('room_visibility'), ('account_status')
  ) as required(name)
  where not exists (
    select 1
    from information_schema.columns c
    where c.table_schema = 'public'
      and c.table_name = 'profiles'
      and c.column_name = required.name
  );
  if v_missing is not null then
    raise exception using
      errcode = 'P0001',
      message = 'friends_v1_incompatible_profiles_columns',
      detail = v_missing;
  end if;

  select string_agg(c.column_name, ', ' order by c.column_name)
    into v_wrong_type
  from information_schema.columns c
  join (
    values
      ('id', 'uuid'),
      ('nickname', 'text'),
      ('friend_code', 'text'),
      ('avatar_key', 'text'),
      ('level', 'integer'),
      ('status_message', 'text'),
      ('room_visibility', 'text'),
      ('account_status', 'text')
  ) as expected(name, data_type)
    on expected.name = c.column_name
  where c.table_schema = 'public'
    and c.table_name = 'profiles'
    and c.data_type <> expected.data_type;
  if v_wrong_type is not null then
    raise exception using
      errcode = 'P0001',
      message = 'friends_v1_incompatible_profiles_types',
      detail = v_wrong_type;
  end if;

  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'profiles'
      and c.contype = 'p'
      and pg_get_constraintdef(c.oid) = 'PRIMARY KEY (id)'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'friends_v1_incompatible_profiles_primary_key';
  end if;
end
$guard$;
do $existing_functions$
declare
  v_existing text;
begin
  if not exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'profiles'
      and c.contype = 'f'
      and pg_get_constraintdef(c.oid) like
        'FOREIGN KEY (id) REFERENCES auth.users(id)%'
  ) then
    raise exception using
      errcode = 'P0001',
      message = 'friends_v1_incompatible_profiles_auth_fk';
  end if;

  select string_agg(signature, ', ' order by signature)
    into v_existing
  from unnest(array[
    'search_friend_profiles(text,integer,uuid)',
    'list_friend_profiles(text)',
    'send_friend_request(uuid,uuid)',
    'respond_friend_request(uuid,boolean)',
    'cancel_friend_request(uuid)',
    'remove_friend(uuid)',
    'set_user_block(uuid,boolean)'
  ]) as signatures(signature)
  where to_regprocedure('public.' || signature) is not null;

  if v_existing is not null then
    raise exception using
      errcode = 'P0001',
      message = 'friends_v1_existing_function_review_required',
      detail = v_existing,
      hint = 'Review function contracts, owners, and grants before applying.';
  end if;
end
$existing_functions$;

create table if not exists public.friend_requests (
  id uuid primary key default gen_random_uuid(),
  requester_id uuid not null references public.profiles(id) on delete cascade,
  receiver_id uuid not null references public.profiles(id) on delete cascade,
  user_low_id uuid generated always as
    (least(requester_id, receiver_id)) stored,
  user_high_id uuid generated always as
    (greatest(requester_id, receiver_id)) stored,
  status text not null default 'pending'
    check (
      status in ('pending', 'accepted', 'rejected', 'expired', 'cancelled')
    ),
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

-- Abort instead of trying to mutate a pre-existing incompatible table.
do $table_contracts$
declare
  v_table text;
  v_column text;
begin
  for v_table, v_column in
    values
      ('friend_requests', 'id'),
      ('friend_requests', 'requester_id'),
      ('friend_requests', 'receiver_id'),
      ('friend_requests', 'user_low_id'),
      ('friend_requests', 'user_high_id'),
      ('friend_requests', 'status'),
      ('friend_requests', 'idempotency_key'),
      ('friend_requests', 'created_at'),
      ('friend_requests', 'updated_at'),
      ('friend_requests', 'responded_at'),
      ('friend_requests', 'expires_at'),
      ('friend_requests', 'cancelled_at'),
      ('friend_requests', 'rejected_at'),
      ('friendships', 'id'),
      ('friendships', 'user_low_id'),
      ('friendships', 'user_high_id'),
      ('friendships', 'created_at'),
      ('user_blocks', 'blocker_id'),
      ('user_blocks', 'blocked_id'),
      ('user_blocks', 'created_at')
  loop
    if not exists (
      select 1
      from information_schema.columns c
      where c.table_schema = 'public'
        and c.table_name = v_table
        and c.column_name = v_column
    ) then
      raise exception using
        errcode = 'P0001',
        message = 'friends_v1_incompatible_existing_table',
        detail = v_table || '.' || v_column;
    end if;
  end loop;
end
$table_contracts$;

create unique index if not exists friend_requests_one_pending_pair_uq
  on public.friend_requests (user_low_id, user_high_id)
  where status = 'pending';
create index if not exists friend_requests_participant_idx
  on public.friend_requests (
    requester_id,
    receiver_id,
    status,
    updated_at desc
  );
create unique index if not exists profiles_friend_code_uq
  on public.profiles (lower(friend_code));
create index if not exists profiles_nickname_search_idx
  on public.profiles using gin (
    lower(nickname) extensions.gin_trgm_ops
  )
  where account_status = 'active';

alter table public.friend_requests enable row level security;
alter table public.friendships enable row level security;
alter table public.user_blocks enable row level security;

do $policies$
begin
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'friend_requests'
      and policyname = 'Participants can read friend requests'
  ) then
    create policy "Participants can read friend requests"
      on public.friend_requests for select to authenticated
      using (auth.uid() in (requester_id, receiver_id));
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'friendships'
      and policyname = 'Participants can read friendships'
  ) then
    create policy "Participants can read friendships"
      on public.friendships for select to authenticated
      using (auth.uid() in (user_low_id, user_high_id));
  end if;
  if not exists (
    select 1 from pg_policies
    where schemaname = 'public'
      and tablename = 'user_blocks'
      and policyname = 'Blockers can read own blocks'
  ) then
    create policy "Blockers can read own blocks"
      on public.user_blocks for select to authenticated
      using (blocker_id = auth.uid());
  end if;
end
$policies$;

revoke all on public.friend_requests, public.friendships, public.user_blocks
  from anon;
revoke insert, update, delete
  on public.friend_requests, public.friendships, public.user_blocks
  from authenticated;

do $functions$
begin
  if to_regprocedure(
    'public.search_friend_profiles(text,integer,uuid)'
  ) is null then
    execute $create$
      create function public.search_friend_profiles(
        p_query text,
        p_limit integer default 20,
        p_cursor uuid default null
      ) returns table (
        user_id uuid,
        nickname text,
        friend_code text,
        avatar_key text,
        level integer,
        status_message text,
        room_visibility text,
        relationship_state text,
        request_id uuid,
        requested_at timestamptz
      )
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      declare
        v_user uuid := auth.uid();
        v_query text := lower(trim(p_query));
      begin
        if v_user is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        if char_length(v_query) < 2 then
          raise exception using
            errcode = '22023', message = 'query_too_short';
        end if;
        p_limit := least(greatest(coalesce(p_limit, 20), 1), 50);
        return query
        select
          p.id, p.nickname, p.friend_code, p.avatar_key, p.level,
          p.status_message, p.room_visibility,
          case
            when p.id = v_user then 'self'
            when bm.blocker_id is not null then 'blockedByMe'
            when bt.blocker_id is not null then 'blockedMe'
            when f.id is not null then 'accepted'
            when r.status = 'pending' and r.requester_id = v_user
              then 'outgoingPending'
            when r.status = 'pending' then 'incomingPending'
            when r.status = 'rejected' then 'rejected'
            when r.status = 'expired'
              or (r.status = 'pending' and r.expires_at <= now())
              then 'expired'
            when r.status = 'cancelled' then 'cancelled'
            else 'none'
          end,
          r.id,
          r.created_at
        from public.profiles p
        left join public.user_blocks bm
          on bm.blocker_id = v_user and bm.blocked_id = p.id
        left join public.user_blocks bt
          on bt.blocker_id = p.id and bt.blocked_id = v_user
        left join public.friendships f
          on f.user_low_id = least(v_user, p.id)
          and f.user_high_id = greatest(v_user, p.id)
        left join lateral (
          select fr.*
          from public.friend_requests fr
          where fr.user_low_id = least(v_user, p.id)
            and fr.user_high_id = greatest(v_user, p.id)
          order by fr.created_at desc
          limit 1
        ) r on true
        where p.account_status = 'active'
          and (p_cursor is null or p.id > p_cursor)
          and (
            lower(p.nickname) % v_query
            or lower(p.friend_code) = v_query
          )
        order by p.id
        limit p_limit;
      end
      $body$
    $create$;
  end if;

  if to_regprocedure('public.list_friend_profiles(text)') is null then
    execute $create$
      create function public.list_friend_profiles(
        p_kind text default 'friends'
      ) returns table (
        user_id uuid,
        nickname text,
        friend_code text,
        avatar_key text,
        level integer,
        status_message text,
        room_visibility text,
        relationship_state text,
        request_id uuid,
        requested_at timestamptz
      )
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      declare
        v_user uuid := auth.uid();
      begin
        if v_user is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        if p_kind not in ('friends', 'incoming', 'recommended') then
          raise exception using
            errcode = '22023', message = 'invalid_list_kind';
        end if;
        return query
        with candidates as (
          select
            case
              when f.user_low_id = v_user then f.user_high_id
              else f.user_low_id
            end as other_id,
            'accepted'::text as relation,
            null::uuid as rid,
            f.created_at as stamp
          from public.friendships f
          where v_user in (f.user_low_id, f.user_high_id)
            and p_kind = 'friends'
          union all
          select
            r.requester_id, 'incomingPending', r.id, r.created_at
          from public.friend_requests r
          where r.receiver_id = v_user
            and r.status = 'pending'
            and r.expires_at > now()
            and p_kind = 'incoming'
          union all
          select p.id, 'none', null::uuid, null::timestamptz
          from public.profiles p
          where p_kind = 'recommended'
            and p.id <> v_user
            and p.account_status = 'active'
            and not exists (
              select 1 from public.friendships f
              where f.user_low_id = least(v_user, p.id)
                and f.user_high_id = greatest(v_user, p.id)
            )
            and not exists (
              select 1 from public.user_blocks b
              where
                (b.blocker_id = v_user and b.blocked_id = p.id)
                or (b.blocker_id = p.id and b.blocked_id = v_user)
            )
        )
        select
          p.id, p.nickname, p.friend_code, p.avatar_key, p.level,
          p.status_message, p.room_visibility,
          c.relation, c.rid, c.stamp
        from candidates c
        join public.profiles p on p.id = c.other_id
        where p.account_status = 'active'
        order by c.stamp desc nulls last
        limit 50;
      end
      $body$
    $create$;
  end if;

  if to_regprocedure('public.send_friend_request(uuid,uuid)') is null then
    execute $create$
      create function public.send_friend_request(
        p_receiver_id uuid,
        p_idempotency_key uuid
      ) returns uuid
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      declare
        v_user uuid := auth.uid();
        v_id uuid;
        v_existing public.friend_requests;
      begin
        if v_user is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        if v_user = p_receiver_id then
          raise exception using errcode = '22023', message = 'self_request';
        end if;
        if not exists (
          select 1 from public.profiles
          where id = p_receiver_id and account_status = 'active'
        ) then
          raise exception using errcode = 'P0002', message = 'user_unavailable';
        end if;
        if exists (
          select 1 from public.user_blocks
          where
            (blocker_id = v_user and blocked_id = p_receiver_id)
            or (blocker_id = p_receiver_id and blocked_id = v_user)
        ) then
          raise exception using
            errcode = '42501', message = 'blocked_relationship';
        end if;
        if exists (
          select 1 from public.friendships
          where user_low_id = least(v_user, p_receiver_id)
            and user_high_id = greatest(v_user, p_receiver_id)
        ) then
          raise exception using errcode = '23505', message = 'already_friends';
        end if;
        select *
          into v_existing
        from public.friend_requests
        where user_low_id = least(v_user, p_receiver_id)
          and user_high_id = greatest(v_user, p_receiver_id)
          and status = 'pending'
        for update;
        if found then
          if v_existing.requester_id = p_receiver_id then
            raise exception using
              errcode = '23505', message = 'incoming_request_exists';
          end if;
          return v_existing.id;
        end if;
        select id
          into v_id
        from public.friend_requests
        where requester_id = v_user
          and idempotency_key = p_idempotency_key;
        if v_id is not null then return v_id; end if;
        insert into public.friend_requests(
          requester_id, receiver_id, idempotency_key
        ) values (
          v_user, p_receiver_id, p_idempotency_key
        ) returning id into v_id;
        return v_id;
      exception
        when unique_violation then
          select id
            into v_id
          from public.friend_requests
          where user_low_id = least(v_user, p_receiver_id)
            and user_high_id = greatest(v_user, p_receiver_id)
            and status = 'pending';
          if v_id is not null then return v_id; end if;
          raise;
      end
      $body$
    $create$;
  end if;

  if to_regprocedure(
    'public.respond_friend_request(uuid,boolean)'
  ) is null then
    execute $create$
      create function public.respond_friend_request(
        p_request_id uuid,
        p_accept boolean
      ) returns void
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      declare
        v_user uuid := auth.uid();
        r public.friend_requests;
      begin
        if v_user is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        select * into r
        from public.friend_requests
        where id = p_request_id
        for update;
        if r.id is null then
          raise exception using errcode = 'P0002', message = 'request_not_found';
        end if;
        if r.receiver_id <> v_user then
          raise exception using errcode = '42501', message = 'receiver_only';
        end if;
        if r.status <> 'pending' then
          raise exception using errcode = '23514', message = 'invalid_transition';
        end if;
        if r.expires_at <= now() then
          update public.friend_requests
          set status = 'expired', updated_at = now()
          where id = r.id;
          raise exception using errcode = '23514', message = 'request_expired';
        end if;
        if exists (
          select 1 from public.user_blocks
          where
            (blocker_id = r.requester_id and blocked_id = r.receiver_id)
            or (blocker_id = r.receiver_id and blocked_id = r.requester_id)
        ) then
          raise exception using
            errcode = '42501', message = 'blocked_relationship';
        end if;
        if p_accept then
          insert into public.friendships(user_low_id, user_high_id)
          values (
            least(r.requester_id, r.receiver_id),
            greatest(r.requester_id, r.receiver_id)
          )
          on conflict do nothing;
          update public.friend_requests
          set status = 'accepted', responded_at = now(), updated_at = now()
          where id = r.id;
        else
          update public.friend_requests
          set
            status = 'rejected',
            rejected_at = now(),
            responded_at = now(),
            updated_at = now()
          where id = r.id;
        end if;
      end
      $body$
    $create$;
  end if;

  if to_regprocedure('public.cancel_friend_request(uuid)') is null then
    execute $create$
      create function public.cancel_friend_request(p_request_id uuid)
      returns void
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      begin
        if auth.uid() is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        update public.friend_requests
        set status = 'cancelled', cancelled_at = now(), updated_at = now()
        where id = p_request_id
          and requester_id = auth.uid()
          and status = 'pending';
        if not found then
          raise exception using errcode = '23514', message = 'invalid_transition';
        end if;
      end
      $body$
    $create$;
  end if;

  if to_regprocedure('public.remove_friend(uuid)') is null then
    execute $create$
      create function public.remove_friend(p_friend_id uuid)
      returns void
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      begin
        if auth.uid() is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        delete from public.friendships
        where user_low_id = least(auth.uid(), p_friend_id)
          and user_high_id = greatest(auth.uid(), p_friend_id);
      end
      $body$
    $create$;
  end if;

  if to_regprocedure('public.set_user_block(uuid,boolean)') is null then
    execute $create$
      create function public.set_user_block(
        p_user_id uuid,
        p_blocked boolean
      ) returns void
      language plpgsql
      security definer
      set search_path = public, pg_temp
      as $body$
      begin
        if auth.uid() is null then
          raise exception using
            errcode = '42501', message = 'authentication_required';
        end if;
        if auth.uid() = p_user_id then
          raise exception using errcode = '22023', message = 'invalid_user';
        end if;
        if p_blocked then
          insert into public.user_blocks(blocker_id, blocked_id)
          values (auth.uid(), p_user_id)
          on conflict do nothing;
          delete from public.friendships
          where user_low_id = least(auth.uid(), p_user_id)
            and user_high_id = greatest(auth.uid(), p_user_id);
          update public.friend_requests
          set status = 'cancelled', cancelled_at = now(), updated_at = now()
          where user_low_id = least(auth.uid(), p_user_id)
            and user_high_id = greatest(auth.uid(), p_user_id)
            and status = 'pending';
        else
          delete from public.user_blocks
          where blocker_id = auth.uid() and blocked_id = p_user_id;
        end if;
      end
      $body$
    $create$;
  end if;
end
$functions$;

revoke all on function public.search_friend_profiles(text, integer, uuid)
  from public;
revoke all on function public.list_friend_profiles(text) from public;
revoke all on function public.send_friend_request(uuid, uuid) from public;
revoke all on function public.respond_friend_request(uuid, boolean)
  from public;
revoke all on function public.cancel_friend_request(uuid) from public;
revoke all on function public.remove_friend(uuid) from public;
revoke all on function public.set_user_block(uuid, boolean) from public;

grant execute on function public.search_friend_profiles(text, integer, uuid)
  to authenticated;
grant execute on function public.list_friend_profiles(text) to authenticated;
grant execute on function public.send_friend_request(uuid, uuid)
  to authenticated;
grant execute on function public.respond_friend_request(uuid, boolean)
  to authenticated;
grant execute on function public.cancel_friend_request(uuid)
  to authenticated;
grant execute on function public.remove_friend(uuid) to authenticated;
grant execute on function public.set_user_block(uuid, boolean)
  to authenticated;

-- Manual rollback / recovery (never run blindly):
-- 1. Revoke EXECUTE from authenticated for the seven functions above.
-- 2. Drop only functions created by this migration, after checking dependents.
-- 3. Preserve tables and data by default. If full removal is approved, archive
--    friend_requests, friendships, and user_blocks before dropping them.
-- 4. Restore any preflight-recorded policies or grants changed by operators.
