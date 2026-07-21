-- P1 Memory Seed system.
-- Safe to run multiple times in Supabase SQL Editor.
-- Creates and patches public.memory_seeds without deleting existing user data.

create table if not exists public.memory_seeds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  seed_type text not null default 'blossom',
  growth_stage text not null default 'seed',
  growth_value integer not null default 0,
  max_growth_value integer not null default 100,
  status text not null default 'growing',
  asset_key text not null default 'seed_blossom_seed',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.memory_seeds
  add column if not exists id uuid default gen_random_uuid(),
  add column if not exists user_id uuid,
  add column if not exists seed_type text,
  add column if not exists growth_stage text,
  add column if not exists growth_value integer,
  add column if not exists max_growth_value integer,
  add column if not exists status text,
  add column if not exists asset_key text,
  add column if not exists created_at timestamptz,
  add column if not exists updated_at timestamptz,
  add column if not exists completed_at timestamptz;

update public.memory_seeds
set seed_type = coalesce(nullif(seed_type, ''), 'blossom'),
    growth_stage = coalesce(nullif(growth_stage, ''), 'seed'),
    growth_value = coalesce(growth_value, 0),
    max_growth_value = coalesce(nullif(max_growth_value, 0), 100),
    status = coalesce(nullif(status, ''), 'growing'),
    asset_key = coalesce(nullif(asset_key, ''), 'seed_blossom_seed'),
    created_at = coalesce(created_at, now()),
    updated_at = coalesce(updated_at, now());

alter table public.memory_seeds
  alter column id set default gen_random_uuid(),
  alter column seed_type set default 'blossom',
  alter column growth_stage set default 'seed',
  alter column growth_value set default 0,
  alter column max_growth_value set default 100,
  alter column status set default 'growing',
  alter column asset_key set default 'seed_blossom_seed',
  alter column created_at set default now(),
  alter column updated_at set default now();

alter table public.memory_seeds
  alter column id set not null,
  alter column user_id set not null,
  alter column seed_type set not null,
  alter column growth_stage set not null,
  alter column growth_value set not null,
  alter column max_growth_value set not null,
  alter column status set not null,
  alter column asset_key set not null,
  alter column created_at set not null,
  alter column updated_at set not null;

-- Ensure primary key exists if the table was created manually without one.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.memory_seeds'::regclass
      and contype = 'p'
  ) then
    alter table public.memory_seeds
      add constraint memory_seeds_pkey primary key (id);
  end if;
end $$;

-- Ensure user_id references auth.users(id) if the table was created manually.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conrelid = 'public.memory_seeds'::regclass
      and conname = 'memory_seeds_user_id_fkey'
  ) then
    alter table public.memory_seeds
      add constraint memory_seeds_user_id_fkey
      foreign key (user_id) references auth.users(id) on delete cascade;
  end if;
end $$;

alter table public.memory_seeds
  drop constraint if exists memory_seeds_growth_value_check;

alter table public.memory_seeds
  add constraint memory_seeds_growth_value_check
  check (growth_value >= 0) not valid;

alter table public.memory_seeds
  drop constraint if exists memory_seeds_max_growth_value_check;

alter table public.memory_seeds
  add constraint memory_seeds_max_growth_value_check
  check (max_growth_value > 0) not valid;

alter table public.memory_seeds
  drop constraint if exists memory_seeds_seed_type_check;

alter table public.memory_seeds
  add constraint memory_seeds_seed_type_check
  check (seed_type in ('blossom', 'baobab', 'maple', 'ginkgo', 'aurora')) not valid;

alter table public.memory_seeds
  drop constraint if exists memory_seeds_growth_stage_check;

alter table public.memory_seeds
  add constraint memory_seeds_growth_stage_check
  check (growth_stage in ('seed', 'sprout', 'leaf', 'flower', 'complete')) not valid;

alter table public.memory_seeds
  drop constraint if exists memory_seeds_status_check;

alter table public.memory_seeds
  add constraint memory_seeds_status_check
  check (status in ('growing', 'completed', 'archived')) not valid;

create index if not exists memory_seeds_user_status_idx
  on public.memory_seeds (user_id, status, created_at desc);

-- Partial unique index requirement: one growing seed per user.
-- Archive older duplicated growing seeds first so index creation does not fail.
with ranked as (
  select id,
         row_number() over (partition by user_id order by created_at desc, updated_at desc, id desc) as rn
  from public.memory_seeds
  where status = 'growing'
)
update public.memory_seeds ms
set status = 'archived',
    updated_at = now()
from ranked r
where ms.id = r.id
  and r.rn > 1;

create unique index if not exists memory_seeds_one_growing_per_user_idx
  on public.memory_seeds (user_id)
  where status = 'growing';

alter table public.memory_seeds enable row level security;

-- RLS policies: users can read/create/update only their own seeds.
drop policy if exists "Users can select own memory seeds" on public.memory_seeds;
drop policy if exists "Users can insert own memory seeds" on public.memory_seeds;
drop policy if exists "Users can update own memory seeds" on public.memory_seeds;

create policy "Users can select own memory seeds"
  on public.memory_seeds
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own memory seeds"
  on public.memory_seeds
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own memory seeds"
  on public.memory_seeds
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- Verification query:
-- select id, user_id, seed_type, growth_stage, growth_value,
--        max_growth_value, status, asset_key, created_at, updated_at, completed_at
-- from public.memory_seeds
-- order by created_at desc;