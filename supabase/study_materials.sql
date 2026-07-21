-- Run this in the Supabase SQL editor.
-- Minimal MVP table for uploaded study materials and AI1 concept extraction.

create table if not exists public.study_materials (
  id uuid primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  title text not null,
  source_type text not null check (source_type in ('pdf', 'image', 'camera', 'text')),
  file_hash text not null,
  storage_path text,
  raw_text text,
  structured_text text,
  status text not null default 'uploaded' check (status in ('uploading', 'uploaded', 'parsing', 'extracting', 'analyzing', 'concepts_completed', 'generating', 'questions_generating', 'completed', 'failed')),
  analysis_error text,
  analysis_completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.study_materials
  add column if not exists raw_text text,
  add column if not exists structured_text text,
  add column if not exists analysis_error text,
  add column if not exists analysis_completed_at timestamptz,
  add column if not exists updated_at timestamptz not null default now();

alter table public.study_materials
  drop constraint if exists study_materials_status_check;

alter table public.study_materials
  add constraint study_materials_status_check
  check (status in ('uploading', 'uploaded', 'parsing', 'extracting', 'analyzing', 'concepts_completed', 'generating', 'questions_generating', 'completed', 'failed'));

create index if not exists study_materials_user_file_hash_idx
  on public.study_materials (user_id, file_hash);

create table if not exists public.concepts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  material_id uuid not null references public.study_materials(id) on delete cascade,
  name text not null,
  description text,
  importance integer not null default 3 check (importance between 1 and 5),
  evidence jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  unique (material_id, name)
);

create index if not exists concepts_user_material_idx
  on public.concepts (user_id, material_id);

alter table public.study_materials enable row level security;
alter table public.concepts enable row level security;

drop policy if exists "Users can select own study materials" on public.study_materials;
drop policy if exists "Users can insert own study materials" on public.study_materials;
drop policy if exists "Users can update own study materials" on public.study_materials;

create policy "Users can select own study materials"
  on public.study_materials
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own study materials"
  on public.study_materials
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own study materials"
  on public.study_materials
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "Users can select own concepts" on public.concepts;
drop policy if exists "Users can insert own concepts" on public.concepts;
drop policy if exists "Users can update own concepts" on public.concepts;

create policy "Users can select own concepts"
  on public.concepts
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own concepts"
  on public.concepts
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own concepts"
  on public.concepts
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create table if not exists public.questions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  material_id uuid not null references public.study_materials(id) on delete cascade,
  concept_id uuid not null references public.concepts(id) on delete cascade,
  section_id uuid,
  source_hash text not null,
  type text not null check (type in ('short_answer', 'multiple_choice', 'fill_blank')),
  question_text text not null,
  options jsonb not null default '[]'::jsonb,
  answer text not null,
  explanation text not null,
  evidence jsonb not null default '{}'::jsonb,
  difficulty integer not null default 3 check (difficulty between 1 and 5),
  initial_batch boolean not null default true,
  order_index integer not null,
  created_at timestamptz not null default now(),
  unique (material_id, order_index)
);

create index if not exists questions_user_material_idx
  on public.questions (user_id, material_id);

create index if not exists questions_user_source_hash_idx
  on public.questions (user_id, source_hash);

alter table public.questions enable row level security;

drop policy if exists "Users can select own questions" on public.questions;
drop policy if exists "Users can insert own questions" on public.questions;
drop policy if exists "Users can update own questions" on public.questions;

create policy "Users can select own questions"
  on public.questions
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own questions"
  on public.questions
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own questions"
  on public.questions
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create table if not exists public.quiz_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  material_id uuid not null references public.study_materials(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  selected_answer text not null,
  is_correct boolean not null,
  response_time_ms integer not null default 0,
  attempted_at timestamptz not null default now()
);

create index if not exists quiz_attempts_user_material_idx
  on public.quiz_attempts (user_id, material_id);

alter table public.quiz_attempts enable row level security;

drop policy if exists "Users can select own quiz attempts" on public.quiz_attempts;
drop policy if exists "Users can insert own quiz attempts" on public.quiz_attempts;

create policy "Users can select own quiz attempts"
  on public.quiz_attempts
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own quiz attempts"
  on public.quiz_attempts
  for insert
  to authenticated
  with check (auth.uid() = user_id);
create table if not exists public.question_feedback (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  feedback_type text not null check (feedback_type in ('like', 'hard', 'inaccurate')),
  created_at timestamptz not null default now(),
  unique (user_id, question_id, feedback_type)
);

create index if not exists question_feedback_user_question_idx
  on public.question_feedback (user_id, question_id);

alter table public.question_feedback enable row level security;

drop policy if exists "Users can select own question feedback" on public.question_feedback;
drop policy if exists "Users can insert own question feedback" on public.question_feedback;
drop policy if exists "Users can delete own question feedback" on public.question_feedback;

create policy "Users can select own question feedback"
  on public.question_feedback
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own question feedback"
  on public.question_feedback
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can delete own question feedback"
  on public.question_feedback
  for delete
  to authenticated
  using (auth.uid() = user_id);
create table if not exists public.memory_states (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  material_id uuid not null references public.study_materials(id) on delete cascade,
  concept_id uuid not null references public.concepts(id) on delete cascade,
  memory_score double precision not null default 0 check (memory_score >= 0 and memory_score <= 1),
  accuracy_score double precision not null default 0 check (accuracy_score >= 0 and accuracy_score <= 1),
  response_time_score double precision not null default 0 check (response_time_score >= 0 and response_time_score <= 1),
  difficulty_score double precision not null default 0 check (difficulty_score >= 0 and difficulty_score <= 1),
  forgetting_curve_score double precision not null default 1 check (forgetting_curve_score >= 0 and forgetting_curve_score <= 1),
  confidence_score double precision not null default 0.5 check (confidence_score >= 0 and confidence_score <= 1),
  last_reviewed_at timestamptz not null default now(),
  next_review_at timestamptz not null default now(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, material_id, concept_id)
);

create index if not exists memory_states_user_next_review_idx
  on public.memory_states (user_id, next_review_at);

alter table public.memory_states enable row level security;

drop policy if exists "Users can select own memory states" on public.memory_states;
drop policy if exists "Users can insert own memory states" on public.memory_states;
drop policy if exists "Users can update own memory states" on public.memory_states;

create policy "Users can select own memory states"
  on public.memory_states
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own memory states"
  on public.memory_states
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own memory states"
  on public.memory_states
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create table if not exists public.review_schedules (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  material_id uuid not null references public.study_materials(id) on delete cascade,
  concept_id uuid not null references public.concepts(id) on delete cascade,
  memory_state_id uuid not null references public.memory_states(id) on delete cascade,
  scheduled_at timestamptz not null,
  status text not null default 'scheduled' check (status in ('scheduled', 'completed', 'skipped')),
  created_at timestamptz not null default now()
);

create index if not exists review_schedules_user_scheduled_idx
  on public.review_schedules (user_id, scheduled_at);

alter table public.review_schedules
  drop constraint if exists review_schedules_user_id_material_id_concept_id_status_key;

create unique index if not exists review_schedules_one_scheduled_idx
  on public.review_schedules (user_id, material_id, concept_id)
  where status = 'scheduled';

alter table public.review_schedules enable row level security;

drop policy if exists "Users can select own review schedules" on public.review_schedules;
drop policy if exists "Users can insert own review schedules" on public.review_schedules;
drop policy if exists "Users can update own review schedules" on public.review_schedules;

create policy "Users can select own review schedules"
  on public.review_schedules
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own review schedules"
  on public.review_schedules
  for insert
  to authenticated
  with check (auth.uid() = user_id);

create policy "Users can update own review schedules"
  on public.review_schedules
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);
create table if not exists public.user_wallets (
  user_id uuid primary key references auth.users(id) on delete cascade,
  balance integer not null default 0 check (balance >= 0),
  total_earned integer not null default 0 check (total_earned >= 0),
  total_spent integer not null default 0 check (total_spent >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_wallets enable row level security;

drop policy if exists "Users can select own wallet" on public.user_wallets;
drop policy if exists "Users can insert own wallet" on public.user_wallets;
drop policy if exists "Users can update own wallet" on public.user_wallets;

create policy "Users can select own wallet"
  on public.user_wallets
  for select
  to authenticated
  using (auth.uid() = user_id);

create table if not exists public.coin_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  transaction_type text not null,
  amount integer not null check (amount <> 0),
  reason text not null,
  reference_id uuid not null,
  idempotency_key text not null,
  source_type text not null,
  source_id uuid not null,
  created_at timestamptz not null default now()
);

alter table public.coin_transactions
  add column if not exists reason text,
  add column if not exists reference_id uuid,
  add column if not exists idempotency_key text,
  add column if not exists source_type text,
  add column if not exists source_id uuid;

update public.coin_transactions
set reason = coalesce(reason, transaction_type),
    reference_id = coalesce(reference_id, source_id),
    idempotency_key = coalesce(
      idempotency_key,
      transaction_type || ':' || coalesce(source_type, 'legacy') || ':' || coalesce(source_id::text, id::text)
    )
where reason is null
   or reference_id is null
   or idempotency_key is null;

alter table public.coin_transactions
  alter column reason set not null,
  alter column reference_id set not null,
  alter column idempotency_key set not null,
  alter column source_type set not null,
  alter column source_id set not null;

alter table public.coin_transactions
  drop constraint if exists coin_transactions_transaction_type_check;

alter table public.coin_transactions
  add constraint coin_transactions_transaction_type_check
  check (transaction_type in (
    'correct_answer',
    'streak_bonus',
    'review_complete',
    'memory_increase',
    'first_study',
    'today_goal_complete',
    'achievement_reward',
    'room_purchase',
    'streak_7_bonus',
    'streak_30_bonus',
    'streak_100_bonus'
  ));

alter table public.coin_transactions
  drop constraint if exists coin_transactions_source_type_check;

alter table public.coin_transactions
  add constraint coin_transactions_source_type_check
  check (source_type in (
    'quiz',
    'review',
    'memory',
    'study',
    'goal',
    'achievement',
    'room_item',
    'streak'
  ));

create index if not exists coin_transactions_user_created_idx
  on public.coin_transactions (user_id, created_at desc);

create unique index if not exists coin_transactions_user_idempotency_key_idx
  on public.coin_transactions (user_id, idempotency_key);

alter table public.coin_transactions enable row level security;

drop policy if exists "Users can select own coin transactions" on public.coin_transactions;
drop policy if exists "Users can insert own coin transactions" on public.coin_transactions;

create policy "Users can select own coin transactions"
  on public.coin_transactions
  for select
  to authenticated
  using (auth.uid() = user_id);

create or replace function public.award_m_coin(
  p_amount integer,
  p_transaction_type text,
  p_source_type text,
  p_source_id uuid,
  p_reason text default null,
  p_reference_id uuid default null,
  p_idempotency_key text default null
)
returns table (
  awarded_amount integer,
  balance integer,
  total_earned integer,
  bonus_amount integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_inserted_amount integer := 0;
  v_balance integer := 0;
  v_total_earned integer := 0;
  v_bonus_amount integer := 0;
  v_expected_amount integer := 0;
  v_reason text := coalesce(nullif(p_reason, ''), p_transaction_type);
  v_reference_id uuid := coalesce(p_reference_id, p_source_id);
  v_idempotency_key text := coalesce(
    nullif(p_idempotency_key, ''),
    p_source_type || ':' || p_transaction_type || ':' || p_source_id::text
  );
begin
  if v_user_id is null then
    raise exception 'Authentication is required.';
  end if;

  v_expected_amount := case p_transaction_type
    when 'correct_answer' then 1
    when 'streak_bonus' then 2
    when 'review_complete' then 20
    when 'memory_increase' then 50
    when 'first_study' then 10
    when 'today_goal_complete' then 20
    when 'achievement_reward' then p_amount
    else 0
  end;

  if v_expected_amount = 0 or p_amount <> v_expected_amount then
    raise exception 'Invalid coin award policy.';
  end if;

  if p_amount <= 0 then
    raise exception 'Award amount must be positive.';
  end if;

  if p_transaction_type = 'correct_answer' and not exists (
    select 1
    from public.quiz_attempts qa
    where qa.user_id = v_user_id
      and qa.question_id = p_source_id
      and qa.is_correct = true
  ) then
    raise exception 'Correct answer source was not found.';
  end if;

  if p_transaction_type = 'first_study' and not exists (
    select 1
    from public.quiz_attempts qa
    where qa.user_id = v_user_id
      and qa.material_id = p_source_id
  ) then
    raise exception 'First study source was not found.';
  end if;

  if p_transaction_type = 'memory_increase' and not exists (
    select 1
    from public.memory_states ms
    where ms.user_id = v_user_id
      and ms.concept_id = p_source_id
  ) then
    raise exception 'Memory source was not found.';
  end if;

  if p_transaction_type = 'review_complete' and not exists (
    select 1
    from public.review_schedules rs
    where rs.user_id = v_user_id
      and rs.id = p_source_id
      and rs.status = 'completed'
  ) then
    raise exception 'Review source was not found.';
  end if;

  if p_transaction_type = 'streak_bonus' and p_source_type = 'quiz' and not exists (
    select 1
    from public.quiz_attempts qa
    where qa.user_id = v_user_id
      and qa.material_id = p_source_id
  ) then
    raise exception 'Quiz streak source was not found.';
  end if;

  if p_transaction_type = 'streak_bonus' and p_source_type = 'review' and not exists (
    select 1
    from public.review_schedules rs
    where rs.user_id = v_user_id
      and rs.id = p_source_id
      and rs.status = 'completed'
  ) then
    raise exception 'Review streak source was not found.';
  end if;

  insert into public.user_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  insert into public.coin_transactions (
    user_id,
    amount,
    transaction_type,
    reason,
    reference_id,
    idempotency_key,
    source_type,
    source_id
  )
  values (
    v_user_id,
    p_amount,
    p_transaction_type,
    v_reason,
    v_reference_id,
    v_idempotency_key,
    p_source_type,
    p_source_id
  )
  on conflict (user_id, idempotency_key) do nothing
  returning amount into v_inserted_amount;

  if v_inserted_amount is not null and v_inserted_amount > 0 then
    update public.user_wallets
    set balance = balance + v_inserted_amount,
        total_earned = total_earned + v_inserted_amount,
        updated_at = now()
    where user_id = v_user_id;
  else
    v_inserted_amount := 0;
  end if;

  select w.balance, w.total_earned
  into v_balance, v_total_earned
  from public.user_wallets w
  where w.user_id = v_user_id;

  if p_transaction_type in (
    'streak_bonus',
    'review_complete',
    'memory_increase',
    'first_study',
    'today_goal_complete',
    'achievement_reward'
  ) then
    v_bonus_amount := v_inserted_amount;
  end if;

  return query select v_inserted_amount, v_balance, v_total_earned, v_bonus_amount;
end;
$$;

create table if not exists public.room_items (
  id uuid primary key default gen_random_uuid(),
  item_code text not null unique,
  name text not null,
  item_type text not null check (item_type in ('chair', 'desk', 'plant', 'lamp')),
  price integer not null check (price >= 0),
  asset_path text not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.room_items enable row level security;

drop policy if exists "Anyone can select active room items" on public.room_items;

create policy "Anyone can select active room items"
  on public.room_items
  for select
  to authenticated
  using (is_active = true);

insert into public.room_items (item_code, name, item_type, price, asset_path, is_active)
values
  ('basic_chair', 'Basic Chair', 'chair', 30, 'assets/room/basic_chair.png', true),
  ('basic_desk', 'Basic Desk', 'desk', 60, 'assets/room/basic_desk.png', true),
  ('small_plant', 'Small Plant', 'plant', 25, 'assets/room/small_plant.png', true),
  ('basic_lamp', 'Basic Lamp', 'lamp', 40, 'assets/room/basic_lamp.png', true)
on conflict (item_code) do update
set name = excluded.name,
    item_type = excluded.item_type,
    price = excluded.price,
    asset_path = excluded.asset_path,
    is_active = excluded.is_active;

create table if not exists public.user_items (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references public.room_items(id) on delete cascade,
  purchased_at timestamptz not null default now(),
  unique (user_id, item_id)
);

create index if not exists user_items_user_idx
  on public.user_items (user_id);

alter table public.user_items enable row level security;

drop policy if exists "Users can select own items" on public.user_items;
drop policy if exists "Users can insert own items" on public.user_items;

create policy "Users can select own items"
  on public.user_items
  for select
  to authenticated
  using (auth.uid() = user_id);

create table if not exists public.user_room_layouts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  item_id uuid not null references public.room_items(id) on delete cascade,
  position_x double precision not null default 0.5 check (position_x >= 0 and position_x <= 1),
  position_y double precision not null default 0.5 check (position_y >= 0 and position_y <= 1),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, item_id)
);

create index if not exists user_room_layouts_user_idx
  on public.user_room_layouts (user_id);

alter table public.user_room_layouts enable row level security;

drop policy if exists "Users can select own room layouts" on public.user_room_layouts;
drop policy if exists "Users can insert own room layouts" on public.user_room_layouts;
drop policy if exists "Users can update own room layouts" on public.user_room_layouts;

create policy "Users can select own room layouts"
  on public.user_room_layouts
  for select
  to authenticated
  using (auth.uid() = user_id);

create policy "Users can insert own room layouts"
  on public.user_room_layouts
  for insert
  to authenticated
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.user_items ui
      where ui.user_id = auth.uid()
        and ui.item_id = user_room_layouts.item_id
    )
  );

create policy "Users can update own room layouts"
  on public.user_room_layouts
  for update
  to authenticated
  using (auth.uid() = user_id)
  with check (
    auth.uid() = user_id
    and exists (
      select 1
      from public.user_items ui
      where ui.user_id = auth.uid()
        and ui.item_id = user_room_layouts.item_id
    )
  );

create or replace function public.purchase_room_item(p_item_id uuid)
returns table (
  purchased_item_id uuid,
  balance integer,
  spent_amount integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_price integer;
  v_balance integer := 0;
  v_user_item_id uuid;
  v_idempotency_key text;
begin
  if v_user_id is null then
    raise exception 'Authentication is required.';
  end if;

  select price
  into v_price
  from public.room_items
  where id = p_item_id
    and is_active = true;

  if v_price is null then
    raise exception 'Room item was not found.';
  end if;

  insert into public.user_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select balance
  into v_balance
  from public.user_wallets
  where user_id = v_user_id
  for update;

  if exists (
    select 1
    from public.user_items ui
    where ui.user_id = v_user_id
      and ui.item_id = p_item_id
  ) then
    return query select p_item_id, v_balance, 0;
    return;
  end if;

  if v_balance < v_price then
    raise exception 'Not enough M-Coin.';
  end if;

  insert into public.user_items (user_id, item_id)
  values (v_user_id, p_item_id)
  on conflict (user_id, item_id) do nothing
  returning id into v_user_item_id;

  if v_user_item_id is null then
    select w.balance
    into v_balance
    from public.user_wallets w
    where w.user_id = v_user_id;
    return query select p_item_id, v_balance, 0;
    return;
  end if;

  update public.user_wallets
  set balance = balance - v_price,
      total_spent = total_spent + v_price,
      updated_at = now()
  where user_id = v_user_id
  returning user_wallets.balance into v_balance;

  v_idempotency_key := 'room_item:room_purchase:' || p_item_id::text;

  insert into public.coin_transactions (
    user_id,
    amount,
    transaction_type,
    reason,
    reference_id,
    idempotency_key,
    source_type,
    source_id
  )
  values (
    v_user_id,
    -v_price,
    'room_purchase',
    'Room item purchase',
    p_item_id,
    v_idempotency_key,
    'room_item',
    p_item_id
  )
  on conflict (user_id, idempotency_key) do nothing;

  return query select p_item_id, v_balance, v_price;
end;
$$;

create table if not exists public.user_streaks (
  user_id uuid primary key references auth.users(id) on delete cascade,
  current_streak integer not null default 0 check (current_streak >= 0),
  max_streak integer not null default 0 check (max_streak >= 0),
  last_studied_on date,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.user_streaks enable row level security;

drop policy if exists "Users can select own streak" on public.user_streaks;
drop policy if exists "Users can insert own streak" on public.user_streaks;
drop policy if exists "Users can update own streak" on public.user_streaks;

create policy "Users can select own streak"
  on public.user_streaks
  for select
  to authenticated
  using (auth.uid() = user_id);

create or replace function public.record_daily_streak(
  p_source_type text,
  p_source_id uuid
)
returns table (
  current_streak integer,
  max_streak integer,
  milestone_reward integer,
  wallet_balance integer
)
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_today date := current_date;
  v_previous_date date;
  v_current integer := 0;
  v_max integer := 0;
  v_reward integer := 0;
  v_transaction_type text;
  v_balance integer := 0;
  v_idempotency_key text;
begin
  if v_user_id is null then
    raise exception 'Authentication is required.';
  end if;

  if p_source_type = 'quiz' and not exists (
    select 1
    from public.quiz_attempts qa
    where qa.user_id = v_user_id
      and qa.material_id = p_source_id
  ) then
    raise exception 'Quiz study source was not found.';
  end if;

  if p_source_type = 'review' and not exists (
    select 1
    from public.review_schedules rs
    where rs.user_id = v_user_id
      and rs.id = p_source_id
      and rs.status = 'completed'
  ) then
    raise exception 'Review study source was not found.';
  end if;

  if p_source_type not in ('quiz', 'review') then
    raise exception 'Invalid streak source type.';
  end if;

  insert into public.user_wallets (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  insert into public.user_streaks (user_id)
  values (v_user_id)
  on conflict (user_id) do nothing;

  select last_studied_on, current_streak, max_streak
  into v_previous_date, v_current, v_max
  from public.user_streaks
  where user_id = v_user_id
  for update;

  if v_previous_date = v_today then
    select balance into v_balance from public.user_wallets where user_id = v_user_id;
    return query select v_current, v_max, 0, coalesce(v_balance, 0);
    return;
  end if;

  if v_previous_date = v_today - 1 then
    v_current := v_current + 1;
  else
    v_current := 1;
  end if;

  v_max := greatest(v_max, v_current);

  update public.user_streaks
  set current_streak = v_current,
      max_streak = v_max,
      last_studied_on = v_today,
      updated_at = now()
  where user_id = v_user_id;

  if v_current = 7 then
    v_reward := 70;
    v_transaction_type := 'streak_7_bonus';
  elsif v_current = 30 then
    v_reward := 300;
    v_transaction_type := 'streak_30_bonus';
  elsif v_current = 100 then
    v_reward := 1000;
    v_transaction_type := 'streak_100_bonus';
  end if;

  if v_reward > 0 then
    v_idempotency_key := 'streak:' || v_transaction_type || ':' || v_user_id::text;

    insert into public.coin_transactions (
      user_id,
      amount,
      transaction_type,
      reason,
      reference_id,
      idempotency_key,
      source_type,
      source_id
    )
    values (
      v_user_id,
      v_reward,
      v_transaction_type,
      'Streak milestone reward',
      v_user_id,
      v_idempotency_key,
      'streak',
      v_user_id
    )
    on conflict (user_id, idempotency_key) do nothing
    returning amount into v_reward;

    if v_reward is not null and v_reward > 0 then
      update public.user_wallets
      set balance = balance + v_reward,
          total_earned = total_earned + v_reward,
          updated_at = now()
      where user_id = v_user_id;
    else
      v_reward := 0;
    end if;
  end if;

  select balance into v_balance from public.user_wallets where user_id = v_user_id;
  return query select v_current, v_max, v_reward, coalesce(v_balance, 0);
end;
$$;