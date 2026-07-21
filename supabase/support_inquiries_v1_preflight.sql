-- READ ONLY: run before the support migration. No DDL/DML.
select to_regclass('auth.users') auth_users,
       to_regclass('public.profiles') profiles,
       to_regclass('public.study_materials') study_materials,
       to_regclass('public.support_inquiries') support_inquiries,
       to_regclass('public.support_replies') support_replies;

select table_name,column_name,data_type,udt_name,is_nullable,column_default
from information_schema.columns
where table_schema='public'
  and table_name in ('study_materials','support_inquiries','support_replies')
order by table_name,ordinal_position;

select rel.relname table_name, con.conname, con.contype,
       pg_get_constraintdef(con.oid) definition
from pg_constraint con join pg_class rel on rel.oid=con.conrelid
join pg_namespace n on n.oid=rel.relnamespace
where n.nspname='public'
  and rel.relname in ('study_materials','support_inquiries','support_replies')
order by rel.relname,con.conname;

select tablename,policyname,roles,cmd,qual,with_check from pg_policies
where schemaname='public'
  and tablename in ('support_inquiries','support_replies');

select p.oid::regprocedure::text signature, p.prosecdef security_definer,
       p.proconfig function_settings,
       has_function_privilege('anon',p.oid,'EXECUTE') anon_execute,
       has_function_privilege('authenticated',p.oid,'EXECUTE') authenticated_execute,
       has_function_privilege('service_role',p.oid,'EXECUTE') service_role_execute
from pg_proc p join pg_namespace n on n.oid=p.pronamespace
where n.nspname='public'
  and p.proname in ('create_support_inquiry','answer_support_inquiry');