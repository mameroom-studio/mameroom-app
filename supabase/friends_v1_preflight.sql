-- Mameroom Friends v1 production preflight.
-- Read-only: this script does not create, alter, grant, revoke, or update.

with required_profile_columns(column_name, expected_type, nullable_allowed) as (
  values
    ('id', 'uuid', false),
    ('nickname', 'text', false),
    ('friend_code', 'text', false),
    ('avatar_key', 'text', true),
    ('level', 'integer', false),
    ('status_message', 'text', false),
    ('room_visibility', 'text', false),
    ('account_status', 'text', false)
),
actual as (
  select
    c.column_name,
    c.data_type,
    c.is_nullable = 'YES' as is_nullable
  from information_schema.columns c
  where c.table_schema = 'public'
    and c.table_name = 'profiles'
)
select
  'profiles_column' as check_type,
  r.column_name as object_name,
  case
    when a.column_name is null then 'MISSING'
    when a.data_type <> r.expected_type then 'TYPE_MISMATCH'
    when not r.nullable_allowed and a.is_nullable then 'NULLABILITY_MISMATCH'
    else 'OK'
  end as status,
  concat(
    'expected=', r.expected_type,
    ', actual=', coalesce(a.data_type, '<missing>'),
    ', nullable=', coalesce(a.is_nullable::text, '<missing>')
  ) as detail
from required_profile_columns r
left join actual a using (column_name)
order by r.column_name;

select
  'profiles_primary_key' as check_type,
  'public.profiles(id)' as object_name,
  case when exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'profiles'
      and c.contype = 'p'
      and pg_get_constraintdef(c.oid) = 'PRIMARY KEY (id)'
  ) then 'OK' else 'MISSING_OR_DIFFERENT' end as status,
  null::text as detail;

select
  'profiles_auth_fk' as check_type,
  'public.profiles(id) -> auth.users(id)' as object_name,
  case when exists (
    select 1
    from pg_constraint c
    join pg_class t on t.oid = c.conrelid
    join pg_namespace n on n.oid = t.relnamespace
    where n.nspname = 'public'
      and t.relname = 'profiles'
      and c.contype = 'f'
      and pg_get_constraintdef(c.oid) like
        'FOREIGN KEY (id) REFERENCES auth.users(id)%'
  ) then 'OK' else 'MISSING_OR_DIFFERENT' end as status,
  null::text as detail;

with expected(object_type, object_name) as (
  values
    ('table', 'friend_requests'),
    ('table', 'friendships'),
    ('table', 'user_blocks'),
    ('function', 'search_friend_profiles(text,integer,uuid)'),
    ('function', 'list_friend_profiles(text)'),
    ('function', 'send_friend_request(uuid,uuid)'),
    ('function', 'respond_friend_request(uuid,boolean)'),
    ('function', 'cancel_friend_request(uuid)'),
    ('function', 'remove_friend(uuid)'),
    ('function', 'set_user_block(uuid,boolean)')
)
select
  e.object_type as check_type,
  e.object_name,
  case
    when e.object_type = 'table'
      then case when to_regclass('public.' || e.object_name) is null
        then 'MISSING' else 'EXISTS' end
    else case when to_regprocedure('public.' || e.object_name) is null
      then 'MISSING' else 'EXISTS' end
  end as status,
  null::text as detail
from expected e
order by e.object_type, e.object_name;

select
  'function_contract' as check_type,
  p.oid::regprocedure::text as object_name,
  case
    when p.prosecdef
      and p.proconfig @> array['search_path=public, pg_temp']
      then 'OK'
    else 'SECURITY_REVIEW_REQUIRED'
  end as status,
  concat(
    'security_definer=', p.prosecdef,
    ', config=', coalesce(array_to_string(p.proconfig, ';'), '<none>'),
    ', result=', pg_get_function_result(p.oid)
  ) as detail
from pg_proc p
join pg_namespace n on n.oid = p.pronamespace
where n.nspname = 'public'
  and p.proname in (
    'search_friend_profiles',
    'list_friend_profiles',
    'send_friend_request',
    'respond_friend_request',
    'cancel_friend_request',
    'remove_friend',
    'set_user_block'
  )
order by p.proname;

select
  'rls' as check_type,
  c.oid::regclass::text as object_name,
  case when c.relrowsecurity then 'ENABLED' else 'DISABLED' end as status,
  null::text as detail
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname in ('profiles', 'friend_requests', 'friendships', 'user_blocks')
order by c.relname;

select
  'policy' as check_type,
  concat(schemaname, '.', tablename, '.', policyname) as object_name,
  'EXISTS' as status,
  concat(
    'roles=', array_to_string(roles, ','),
    ', cmd=', cmd,
    ', using=', coalesce(qual, '<none>'),
    ', check=', coalesce(with_check, '<none>')
  ) as detail
from pg_policies
where schemaname = 'public'
  and tablename in ('profiles', 'friend_requests', 'friendships', 'user_blocks')
order by tablename, policyname;

select
  'trigger' as check_type,
  concat(event_object_schema, '.', event_object_table, '.', trigger_name)
    as object_name,
  'EXISTS' as status,
  concat(action_timing, ' ', event_manipulation, ' -> ', action_statement)
    as detail
from information_schema.triggers
where event_object_schema = 'public'
  and event_object_table in (
    'profiles',
    'friend_requests',
    'friendships',
    'user_blocks'
  )
order by event_object_table, trigger_name;

select
  'function_privilege' as check_type,
  concat(routine_schema, '.', routine_name, ' -> ', grantee) as object_name,
  privilege_type as status,
  null::text as detail
from information_schema.routine_privileges
where routine_schema = 'public'
  and routine_name in (
    'search_friend_profiles',
    'list_friend_profiles',
    'send_friend_request',
    'respond_friend_request',
    'cancel_friend_request',
    'remove_friend',
    'set_user_block'
  )
order by routine_name, grantee;
