-- Mameroom short_answer cleanup plan
-- Prepared 2026-07-21. DO NOT RUN without explicit approval.
-- Confirm the linked project ref is exactly: zglfjvnjnopilhikkxum
-- This script intentionally targets only the observed value: short_answer.

-- ---------------------------------------------------------------------------
-- A. READ-ONLY PRECHECK (safe to run separately)
-- ---------------------------------------------------------------------------
begin transaction read only;

select current_database() as database_name, current_user as database_role;

select type, count(*)::bigint as question_count,
       count(distinct material_id)::bigint as material_count
from public.questions
group by type
order by type;

with target as (
  select id, material_id, concept_id, source_hash
  from public.questions
  where type = 'short_answer'
), target_materials as (
  select distinct material_id from target
)
select jsonb_build_object(
  'target_questions', (select count(*) from target),
  'target_materials', (select count(*) from target_materials),
  'generation_batches_by_source_hash',
    (select count(distinct source_hash) from target),
  'quiz_attempt_rows',
    (select count(*) from public.quiz_attempts a join target t on t.id = a.question_id),
  'question_feedback_rows',
    (select count(*) from public.question_feedback f join target t on t.id = f.question_id),
  'learning_pass_rows',
    (select count(*) from public.learning_passes p join target t on t.id = p.question_id),
  'questions_remaining',
    (select count(*) from public.questions q
      join target_materials m using (material_id)
      where q.type <> 'short_answer')
) as deletion_precheck;

select q.material_id,
       count(*) filter (where q.type = 'short_answer') as short_answer_count,
       count(*) filter (where q.type = 'multiple_choice') as multiple_choice_count,
       count(*) filter (where q.type = 'fill_blank') as fill_blank_count
from public.questions q
where exists (
  select 1 from public.questions t
  where t.material_id = q.material_id and t.type = 'short_answer'
)
group by q.material_id
order by q.material_id;

rollback;

-- ---------------------------------------------------------------------------
-- B. GUARDED DELETE TRANSACTION
-- Run only after approval and only after repeating section A.
-- Expected snapshot at preparation time:
--   short_answer questions = 7
--   affected materials = 1
--   quiz_attempts = 0
--   question_feedback = 0
--   learning_passes = 1
--   remaining questions in affected materials = 3
-- ---------------------------------------------------------------------------
begin;
select pg_advisory_xact_lock(hashtext('mameroom-short-answer-cleanup-20260721'));

do $guard$
declare
  v_target_questions bigint;
  v_target_materials bigint;
  v_attempts bigint;
  v_feedback bigint;
  v_passes bigint;
  v_unexpected_types bigint;
  v_multiple_choice bigint;
  v_expected_materials bigint;
begin
  select count(*), count(distinct material_id)
    into v_target_questions, v_target_materials
  from public.questions
  where type = 'short_answer';

  select count(*) into v_attempts
  from public.quiz_attempts a
  join public.questions q on q.id = a.question_id
  where q.type = 'short_answer';

  select count(*) into v_feedback
  from public.question_feedback f
  join public.questions q on q.id = f.question_id
  where q.type = 'short_answer';

  select count(*) into v_passes
  from public.learning_passes p
  join public.questions q on q.id = p.question_id
  where q.type = 'short_answer';

  select count(*) into v_unexpected_types
  from public.questions
  where type not in ('short_answer', 'multiple_choice');

  select count(*) into v_multiple_choice
  from public.questions
  where type = 'multiple_choice';

  select count(distinct material_id) into v_expected_materials
  from public.questions
  where type = 'short_answer'
    and material_id = '0f27d37d-a630-4bac-8927-b8bdc7f7b903'::uuid;

  if v_target_questions <> 7 then
    raise exception 'ABORT: expected 7 short_answer questions, found %',
      v_target_questions;
  end if;
  if v_target_materials <> 1 then
    raise exception 'ABORT: expected 1 affected material, found %',
      v_target_materials;
  end if;
  if v_expected_materials <> 1 then
    raise exception 'ABORT: target material id differs from the approved snapshot';
  end if;
  if v_multiple_choice <> 3 then
    raise exception 'ABORT: expected 3 multiple_choice questions, found %',
      v_multiple_choice;
  end if;
  if v_attempts <> 0 then
    raise exception 'ABORT: expected 0 quiz_attempt rows, found %', v_attempts;
  end if;
  if v_feedback <> 0 then
    raise exception 'ABORT: expected 0 question_feedback rows, found %',
      v_feedback;
  end if;
  if v_passes <> 1 then
    raise exception 'ABORT: expected 1 learning_pass row, found %', v_passes;
  end if;
  if v_unexpected_types <> 0 then
    raise exception 'ABORT: unexpected non-MCQ question types found: %',
      v_unexpected_types;
  end if;
end
$guard$;

-- Durable, access-restricted backup for post-commit recovery.
-- Existing backup objects cause an intentional failure and prevent reruns.
create schema mameroom_ops;
revoke all on schema mameroom_ops from public, anon, authenticated;

create table mameroom_ops.short_answer_questions_20260721
  as select * from public.questions where false;
create table mameroom_ops.short_answer_attempts_20260721
  as select * from public.quiz_attempts where false;
create table mameroom_ops.short_answer_feedback_20260721
  as select * from public.question_feedback where false;
create table mameroom_ops.short_answer_passes_20260721
  as select * from public.learning_passes where false;

insert into mameroom_ops.short_answer_questions_20260721
select * from public.questions where type = 'short_answer';

insert into mameroom_ops.short_answer_attempts_20260721
select a.*
from public.quiz_attempts a
join mameroom_ops.short_answer_questions_20260721 q
  on q.id = a.question_id;

insert into mameroom_ops.short_answer_feedback_20260721
select f.*
from public.question_feedback f
join mameroom_ops.short_answer_questions_20260721 q
  on q.id = f.question_id;

insert into mameroom_ops.short_answer_passes_20260721
select p.*
from public.learning_passes p
join mameroom_ops.short_answer_questions_20260721 q
  on q.id = p.question_id;

do $backup_guard$
begin
  if (select count(*) from mameroom_ops.short_answer_questions_20260721) <> 7
     or (select count(*) from mameroom_ops.short_answer_attempts_20260721) <> 0
     or (select count(*) from mameroom_ops.short_answer_feedback_20260721) <> 0
     or (select count(*) from mameroom_ops.short_answer_passes_20260721) <> 1
  then
    raise exception 'ABORT: backup counts do not match the approved snapshot';
  end if;
end
$backup_guard$;

-- Delete children explicitly so affected rows are auditable; do not rely only
-- on ON DELETE CASCADE. The attempt and feedback deletes are expected to be 0.
delete from public.quiz_attempts a
using mameroom_ops.short_answer_questions_20260721 q
where a.question_id = q.id;

delete from public.question_feedback f
using mameroom_ops.short_answer_questions_20260721 q
where f.question_id = q.id;

delete from public.learning_passes p
using mameroom_ops.short_answer_questions_20260721 q
where p.question_id = q.id;

create temporary table deleted_short_answer_ids (id uuid primary key) on commit drop;
with deleted as (
  delete from public.questions q
  using mameroom_ops.short_answer_questions_20260721 backup
  where q.id = backup.id
    and q.type = 'short_answer'
  returning q.id
)
insert into deleted_short_answer_ids(id)
select id from deleted;

do $delete_guard$
begin
  if (select count(*) from deleted_short_answer_ids) <> 7 then
    raise exception 'ABORT: expected to delete 7 questions, deleted %',
      (select count(*) from deleted_short_answer_ids);
  end if;
  if exists (select 1 from public.questions where type = 'short_answer') then
    raise exception 'ABORT: short_answer questions remain';
  end if;
  if exists (
    select 1 from public.quiz_attempts a
    join mameroom_ops.short_answer_questions_20260721 q
      on q.id = a.question_id
  ) or exists (
    select 1 from public.question_feedback f
    join mameroom_ops.short_answer_questions_20260721 q
      on q.id = f.question_id
  ) or exists (
    select 1 from public.learning_passes p
    join mameroom_ops.short_answer_questions_20260721 q
      on q.id = p.question_id
  ) then
    raise exception 'ABORT: child rows remain for deleted questions';
  end if;
end
$delete_guard$;

-- Review these result sets before choosing COMMIT instead of ROLLBACK.
select id as deleted_question_id from deleted_short_answer_ids order by id;

select q.material_id,
       count(*) as playable_question_count,
       count(*) filter (where q.type = 'multiple_choice') as multiple_choice_count,
       count(*) filter (where q.type <> 'multiple_choice') as unexpected_count
from public.questions q
where q.material_id in (
  select distinct material_id
  from mameroom_ops.short_answer_questions_20260721
)
group by q.material_id
order by q.material_id;

-- SAFETY DEFAULT: no deletion persists while this remains ROLLBACK.
rollback;
-- After explicit approval, review all output and replace only the line above
-- with COMMIT. Do not execute both statements.

-- ---------------------------------------------------------------------------
-- C. RESTORE PLAN (run only if a committed cleanup must be reversed)
-- ---------------------------------------------------------------------------
-- begin;
-- insert into public.questions
-- select * from mameroom_ops.short_answer_questions_20260721;
-- insert into public.quiz_attempts
-- select * from mameroom_ops.short_answer_attempts_20260721;
-- insert into public.question_feedback
-- select * from mameroom_ops.short_answer_feedback_20260721;
-- insert into public.learning_passes
-- select * from mameroom_ops.short_answer_passes_20260721;
-- select type, count(*) from public.questions group by type order by type;
-- commit;
