-- Mameroom profiles v1 read-only postflight.

select
  (select count(*) from auth.users) as auth_user_count,
  (select count(*) from public.profiles) as profile_count,
  (
    select count(*)
    from auth.users u
    left join public.profiles p on p.id = u.id
    where p.id is null
  ) as auth_users_without_profile,
  (
    select count(*)
    from public.profiles p
    left join auth.users u on u.id = p.id
    where u.id is null
  ) as profiles_without_auth_user;

select
  c.column_name,
  c.data_type,
  c.is_nullable,
  c.column_default
from information_schema.columns c
where c.table_schema = 'public'
  and c.table_name = 'profiles'
order by c.ordinal_position;

select
  to_regclass('public.profiles') as profiles_relation,
  to_regprocedure('public.handle_new_auth_user_profile()')
    as signup_trigger_function,
  to_regprocedure('public.set_profiles_updated_at()')
    as updated_at_trigger_function,
  has_table_privilege('authenticated', 'public.profiles', 'SELECT')
    as authenticated_can_select,
  has_table_privilege('authenticated', 'public.profiles', 'INSERT')
    as authenticated_can_insert,
  has_table_privilege('authenticated', 'public.profiles', 'UPDATE')
    as authenticated_can_update,
  has_table_privilege('authenticated', 'public.profiles', 'DELETE')
    as authenticated_can_delete;

select
  schemaname,
  tablename,
  policyname,
  roles,
  cmd,
  qual,
  with_check
from pg_policies
where schemaname = 'public'
  and tablename = 'profiles'
order by policyname;

select
  t.tgname as trigger_name,
  pg_get_triggerdef(t.oid) as trigger_definition
from pg_trigger t
join pg_class c on c.oid = t.tgrelid
join pg_namespace n on n.oid = c.relnamespace
where not t.tgisinternal
  and (
    (n.nspname = 'public' and c.relname = 'profiles')
    or (n.nspname = 'auth' and c.relname = 'users')
  )
order by n.nspname, c.relname, t.tgname;
