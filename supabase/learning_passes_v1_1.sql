create table if not exists public.learning_passes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  material_id uuid references public.study_materials(id) on delete cascade,
  question_id uuid references public.questions(id) on delete cascade,
  concept_id uuid references public.concepts(id) on delete cascade,
  pass_type text not null check (pass_type in ('question', 'concept')),
  reason text not null check (reason in ('already_known', 'out_of_scope', 'low_quality', 'review_later')),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  restored_at timestamptz,
  check (
    (pass_type = 'question' and question_id is not null)
    or (pass_type = 'concept' and concept_id is not null)
  )
);

create index if not exists learning_passes_user_material_idx
  on public.learning_passes (user_id, material_id, is_active);

create unique index if not exists learning_passes_active_question_idx
  on public.learning_passes (user_id, question_id)
  where is_active and pass_type = 'question';

create unique index if not exists learning_passes_active_concept_idx
  on public.learning_passes (user_id, concept_id)
  where is_active and pass_type = 'concept';

alter table public.learning_passes enable row level security;

drop policy if exists "Users can select own learning passes" on public.learning_passes;
drop policy if exists "Users can insert own learning passes" on public.learning_passes;
drop policy if exists "Users can update own learning passes" on public.learning_passes;

create policy "Users can select own learning passes"
  on public.learning_passes
  for select
  using (auth.uid() = user_id);

create policy "Users can insert own learning passes"
  on public.learning_passes
  for insert
  with check (auth.uid() = user_id);

create policy "Users can update own learning passes"
  on public.learning_passes
  for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);