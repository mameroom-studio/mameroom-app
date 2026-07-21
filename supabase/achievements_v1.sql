-- Achievement v1. 04-5 policy: server-evaluated completion and automatic,
-- idempotent rewards. Apply after economy_stabilization.sql.
create table if not exists public.achievement_definitions (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  version integer not null default 1 check (version > 0),
  title text not null,
  description text not null,
  category text not null check (category in ('learning','review','memory','growth','friends','collection')),
  condition_type text not null,
  condition_config jsonb not null default '{}'::jsonb,
  condition_label text not null,
  target_value integer not null check (target_value > 0),
  icon_asset text,
  is_active boolean not null default true,
  is_hidden boolean not null default false,
  sort_order integer not null default 0,
  unique (code, version)
);

create table if not exists public.badge_definitions (
  id uuid primary key default gen_random_uuid(),
  code text not null unique,
  name text not null,
  description text not null,
  grade text check (grade is null or grade in ('bronze','silver','gold','platinum','diamond')),
  asset_path text,
  is_active boolean not null default true
);

create table if not exists public.achievement_badge_links (
  achievement_id uuid not null references public.achievement_definitions(id) on delete cascade,
  badge_id uuid not null references public.badge_definitions(id) on delete cascade,
  primary key (achievement_id, badge_id)
);

create table if not exists public.achievement_reward_definitions (
  id uuid primary key default gen_random_uuid(),
  achievement_id uuid not null references public.achievement_definitions(id) on delete cascade,
  reward_key text not null,
  reward_type text not null check (reward_type in ('mCoin','badge','roomDecoration','other')),
  label text not null,
  amount integer check (amount is null or amount > 0),
  badge_id uuid references public.badge_definitions(id),
  room_item_id uuid references public.room_items(id),
  config jsonb not null default '{}'::jsonb,
  unique (achievement_id, reward_key)
);

create table if not exists public.user_achievement_progress (
  user_id uuid not null references auth.users(id) on delete cascade,
  achievement_id uuid not null references public.achievement_definitions(id) on delete cascade,
  progress_value integer not null default 0 check (progress_value >= 0),
  status text not null default 'notStarted' check (status in (
    'notStarted','inProgress','eligible','completing','completed',
    'rewardPending','rewarded','locked','unavailable','expired'
  )),
  completed_at timestamptz,
  rewarded_at timestamptz,
  updated_at timestamptz not null default now(),
  primary key (user_id, achievement_id)
);

create table if not exists public.user_badges (
  user_id uuid not null references auth.users(id) on delete cascade,
  badge_id uuid not null references public.badge_definitions(id) on delete cascade,
  achievement_id uuid references public.achievement_definitions(id),
  unlocked_at timestamptz not null default now(),
  primary key (user_id, badge_id)
);

create table if not exists public.user_achievement_rewards (
  user_id uuid not null references auth.users(id) on delete cascade,
  reward_definition_id uuid not null references public.achievement_reward_definitions(id) on delete cascade,
  idempotency_key text not null,
  delivered_at timestamptz not null default now(),
  payload jsonb not null default '{}'::jsonb,
  primary key (user_id, reward_definition_id),
  unique (idempotency_key)
);

create index if not exists achievement_definitions_active_sort_idx
  on public.achievement_definitions (is_active, category, sort_order);
create index if not exists user_achievement_progress_user_status_idx
  on public.user_achievement_progress (user_id, status);

alter table public.achievement_definitions enable row level security;
alter table public.badge_definitions enable row level security;
alter table public.achievement_badge_links enable row level security;
alter table public.achievement_reward_definitions enable row level security;
alter table public.user_achievement_progress enable row level security;
alter table public.user_badges enable row level security;
alter table public.user_achievement_rewards enable row level security;

create policy "Authenticated users read active achievements" on public.achievement_definitions
  for select to authenticated using (is_active);
create policy "Authenticated users read active badges" on public.badge_definitions
  for select to authenticated using (is_active);
create policy "Authenticated users read achievement badge links" on public.achievement_badge_links
  for select to authenticated using (true);
create policy "Authenticated users read reward definitions" on public.achievement_reward_definitions
  for select to authenticated using (true);
create policy "Users read own achievement progress" on public.user_achievement_progress
  for select to authenticated using (auth.uid() = user_id);
create policy "Users read own badges" on public.user_badges
  for select to authenticated using (auth.uid() = user_id);
create policy "Users read own achievement rewards" on public.user_achievement_rewards
  for select to authenticated using (auth.uid() = user_id);

create or replace function public.get_achievement_overview()
returns table (payload jsonb)
language sql security definer set search_path = public
as $$
  select jsonb_build_object(
    'code', d.code, 'title', d.title, 'description', d.description,
    'category', d.category, 'condition_label', d.condition_label,
    'target_value', d.target_value, 'icon_asset', d.icon_asset,
    'is_hidden', d.is_hidden, 'progress_value', coalesce(p.progress_value, 0),
    'status', coalesce(p.status, 'notStarted'), 'completed_at', p.completed_at,
    'badge_grade', b.grade,
    'rewards', coalesce((
      select jsonb_agg(jsonb_build_object(
        'type', r.reward_type, 'label', r.label, 'amount', r.amount,
        'asset_path', coalesce(bd.asset_path, ri.asset_path),
        'delivered', ur.delivered_at is not null
      ) order by r.reward_key)
      from achievement_reward_definitions r
      left join badge_definitions bd on bd.id = r.badge_id
      left join room_items ri on ri.id = r.room_item_id
      left join user_achievement_rewards ur
        on ur.reward_definition_id = r.id and ur.user_id = auth.uid()
      where r.achievement_id = d.id
    ), '[]'::jsonb)
  )
  from achievement_definitions d
  left join user_achievement_progress p
    on p.achievement_id = d.id and p.user_id = auth.uid()
  left join achievement_badge_links abl on abl.achievement_id = d.id
  left join badge_definitions b on b.id = abl.badge_id
  where auth.uid() is not null and d.is_active
  order by d.sort_order, d.code;
$$;

create or replace function public.confirm_achievement_reward(p_achievement_code text)
returns table (payload jsonb)
language plpgsql security definer set search_path = public
as $$
declare
  v_user uuid := auth.uid();
  v_achievement achievement_definitions%rowtype;
  v_progress user_achievement_progress%rowtype;
begin
  if v_user is null then raise exception 'Authentication is required.'; end if;
  select * into v_achievement from achievement_definitions
    where code = p_achievement_code and is_active order by version desc limit 1;
  select * into v_progress from user_achievement_progress
    where user_id = v_user and achievement_id = v_achievement.id for update;
  if v_progress.status not in ('completed','rewardPending','rewarded') then
    raise exception 'Achievement is not complete.';
  end if;
  -- Rewards are issued only by the server-side evaluator. This RPC confirms
  -- delivery state and never creates coins, badges, or room items.
  update user_achievement_progress
    set status = case when exists (
      select 1 from achievement_reward_definitions r
      where r.achievement_id = v_achievement.id
      and not exists (select 1 from user_achievement_rewards ur
        where ur.user_id = v_user and ur.reward_definition_id = r.id)
    ) then 'rewardPending' else 'rewarded' end,
    rewarded_at = case when status = 'rewarded' then coalesce(rewarded_at, now()) else rewarded_at end,
    updated_at = now()
    where user_id = v_user and achievement_id = v_achievement.id;
  return query select g.payload from get_achievement_overview() g
    where g.payload->>'code' = p_achievement_code;
end;
$$;

revoke all on function public.get_achievement_overview() from public;
revoke all on function public.confirm_achievement_reward(text) from public;
grant execute on function public.get_achievement_overview() to authenticated;
grant execute on function public.confirm_achievement_reward(text) to authenticated;
