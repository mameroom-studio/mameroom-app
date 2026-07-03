-- AI1 concept quality metadata for exam-worthy concept extraction.
-- Run this in the Supabase SQL editor before deploying the updated Edge Functions.

alter table public.concepts
  add column if not exists importance_score integer,
  add column if not exists concept_type text,
  add column if not exists evaluation jsonb not null default '{}'::jsonb,
  add column if not exists exclusion_reason text;

update public.concepts
set importance_score = coalesce(importance_score, least(100, greatest(0, importance * 20))),
    concept_type = coalesce(concept_type, 'core_concept'),
    evaluation = coalesce(evaluation, '{}'::jsonb)
where importance_score is null
   or concept_type is null
   or evaluation is null;

alter table public.concepts
  drop constraint if exists concepts_importance_score_range;

alter table public.concepts
  add constraint concepts_importance_score_range
  check (importance_score is null or importance_score between 0 and 100);

alter table public.concepts
  drop constraint if exists concepts_concept_type_check;

alter table public.concepts
  add constraint concepts_concept_type_check
  check (
    concept_type is null or concept_type in (
      'core_concept',
      'technical_term',
      'definition',
      'formula_or_metric',
      'regulation_or_standard',
      'process_step',
      'comparison_point',
      'prerequisite_concept',
      'acronym',
      'case_or_example',
      'metadata_noise',
      'generic_noise'
    )
  );

create index if not exists concepts_quality_generation_idx
  on public.concepts (user_id, material_id, importance_score desc)
  where exclusion_reason is null;
