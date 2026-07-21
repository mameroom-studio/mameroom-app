-- PDF analysis migration only.
-- Safe to run in the Supabase SQL Editor.
--
-- Scope:
-- - public.study_materials PDF analysis columns only
-- - excludes unrelated feature schema and data changes
--
-- Important order:
-- 1. Add missing PDF analysis columns.
-- 2. Drop existing status CHECK constraints first.
-- 3. Normalize legacy status values without deleting data.
-- 4. Add the new status CHECK constraint.

alter table if exists public.study_materials
  add column if not exists file_hash text,
  add column if not exists storage_path text,
  add column if not exists raw_text text,
  add column if not exists structured_text text,
  add column if not exists status text,
  add column if not exists analysis_error text,
  add column if not exists analysis_completed_at timestamptz;

do $$
declare
  constraint_record record;
begin
  if to_regclass('public.study_materials') is null then
    raise notice 'public.study_materials does not exist. Skipping PDF analysis migration.';
    return;
  end if;

  -- Drop existing CHECK constraints that validate the status column before updating data.
  -- This avoids failures when legacy allowed values are converted to the new canonical values.
  for constraint_record in
    select con.conname
    from pg_constraint con
    join pg_class rel on rel.oid = con.conrelid
    join pg_namespace nsp on nsp.oid = rel.relnamespace
    where nsp.nspname = 'public'
      and rel.relname = 'study_materials'
      and con.contype = 'c'
      and pg_get_constraintdef(con.oid) ilike '%status%'
  loop
    execute format(
      'alter table public.study_materials drop constraint if exists %I',
      constraint_record.conname
    );
  end loop;

  -- Normalize legacy / intermediate statuses without deleting rows.
  update public.study_materials
  set status = case
    when status in ('uploading', 'parsing', 'generating', 'completed', 'failed') then status
    when status is null or btrim(status) = '' then 'uploading'
    when status = 'uploaded' then 'uploading'
    when status in ('extracting', 'analyzing', 'concepts_completed', 'questions_generating') then 'generating'
    else 'failed'
  end
  where status is null
     or btrim(status) = ''
     or status not in ('uploading', 'parsing', 'generating', 'completed', 'failed');

  alter table public.study_materials
    alter column status set default 'uploading';

  alter table public.study_materials
    alter column status set not null;

  alter table public.study_materials
    add constraint study_materials_status_check
    check (status in ('uploading', 'parsing', 'generating', 'completed', 'failed'));
end $$;