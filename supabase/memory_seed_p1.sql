-- P1 Memory Seed system.
-- Safe to run multiple times. Does not delete existing user data.

create table if not exists public.memory_seeds (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  seed_type text not null default 'blossom',
  growth_stage text not null default 'seed',
  growth_value integer not null default 0 check (growth_value >= 0),
  max_growth_value integer not null default 100 check (max_growth_value > 0),
  status text not null default 'growing',
  asset_key text not null default 'seed_blossom_seed',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

alter table public.memory_seeds
  drop constraint if exists memory_seeds_seed_type_check;

alter table public.memory_seeds
  add constraint memory_seeds_seed_type_check
  check (seed_type in ('blossom', 'baobab', 'maple', 'ginkgo', 'aurora'));

alter table public.memory_seeds
  drop constraint if exists memory_seeds_growth_stage_check;

alter table public.memory_seeds
  add constraint memory_seeds_growth_stage_check
  check (growth_stage in ('seed', 'sprout', 'leaf', 'flower', 'complete'));

alter table public.memory_seeds
  drop constraint if exists memory_seeds_status_check;

alter table public.memory_seeds
  add constraint memory_seeds_status_check
  check (status in ('growing', 'completed', 'archived'));

create index if not exists memory_seeds_user_status_idx
  on public.memory_seeds (user_id, status, created_at desc);

create unique index if not exists memory_seeds_one_growing_per_user_idx
  on public.memory_seeds (user_id)
  where status = 'growing';

alter table public.memory_seeds enable row level security;

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
