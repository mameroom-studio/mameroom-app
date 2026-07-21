-- Memory Engine v2 (FSRS-6) additive schema. DO NOT auto-apply to production.
-- Existing memory_states/review_schedules/quiz_attempts remain the legacy_v1 fallback.

create table if not exists public.question_memory_states_v2 (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  state text not null check (state in ('new','learning','review','relearning')),
  due_at timestamptz not null,
  last_reviewed_at timestamptz,
  stability double precision not null check (stability >= 0),
  difficulty double precision not null check (difficulty >= 1 and difficulty <= 10),
  elapsed_days integer not null default 0 check (elapsed_days >= 0),
  scheduled_days integer not null default 0 check (scheduled_days >= 0),
  reps integer not null default 0 check (reps >= 0),
  lapses integer not null default 0 check (lapses >= 0),
  learning_steps integer not null default 0 check (learning_steps >= 0),
  last_rating smallint check (last_rating between 1 and 4),
  engine_version text not null default 'fsrs_v2',
  algorithm_version text not null default 'fsrs-6',
  parameter_version text not null default 'fsrs-6-default-v1',
  state_version bigint not null default 1 check (state_version > 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (user_id, question_id)
);

create index if not exists question_memory_states_v2_due_idx
  on public.question_memory_states_v2 (user_id, due_at, stability, question_id);

create table if not exists public.memory_submissions_v2 (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  session_id uuid,
  event_type text not null check (event_type in ('initial','review','voluntary','pass')),
  status text not null default 'pending' check (status in ('pending','completed','failed')),
  reviewed_at timestamptz not null,
  expected_state_version bigint,
  response jsonb,
  failure_code text,
  duplicate_count integer not null default 0 check (duplicate_count >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists memory_submissions_v2_user_created_idx
  on public.memory_submissions_v2 (user_id, created_at desc);

create table if not exists public.memory_review_logs_v2 (
  id uuid primary key default gen_random_uuid(),
  submission_id uuid not null unique references public.memory_submissions_v2(submission_id) on delete restrict,
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  memory_state_id uuid references public.question_memory_states_v2(id) on delete set null,
  event_type text not null check (event_type in ('initial','review','voluntary','pass')),
  rating smallint check (rating between 1 and 4),
  pass_action text check (pass_action in ('deferred','known','out_of_scope','quality_issue','neutral')),
  previous_state text,
  next_state text,
  previous_due_at timestamptz,
  next_due_at timestamptz,
  elapsed_days integer not null default 0,
  scheduled_days integer not null default 0,
  response_time_ms integer not null default 0 check (response_time_ms >= 0),
  retry_count integer not null default 0 check (retry_count >= 0),
  hint_level integer not null default 0 check (hint_level between 0 and 2),
  is_correct boolean,
  engine_version text not null,
  algorithm_version text not null,
  parameter_version text not null,
  fallback_used boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists memory_review_logs_v2_user_question_idx
  on public.memory_review_logs_v2 (user_id, question_id, created_at desc);

create table if not exists public.question_learning_preferences_v2 (
  user_id uuid not null references auth.users(id) on delete cascade,
  question_id uuid not null references public.questions(id) on delete cascade,
  status text not null check (status in ('active','deferred','known','out_of_scope','quality_issue')),
  reason text,
  updated_at timestamptz not null default now(),
  primary key (user_id, question_id)
);

alter table public.question_memory_states_v2 enable row level security;
alter table public.memory_submissions_v2 enable row level security;
alter table public.memory_review_logs_v2 enable row level security;
alter table public.question_learning_preferences_v2 enable row level security;

create policy "Users select own v2 memory states" on public.question_memory_states_v2
  for select to authenticated using (auth.uid() = user_id);
create policy "Users select own v2 submissions" on public.memory_submissions_v2
  for select to authenticated using (auth.uid() = user_id);
create policy "Users select own v2 review logs" on public.memory_review_logs_v2
  for select to authenticated using (auth.uid() = user_id);
create policy "Users select own v2 preferences" on public.question_learning_preferences_v2
  for select to authenticated using (auth.uid() = user_id);

revoke insert, update, delete on public.question_memory_states_v2 from anon, authenticated;
revoke insert, update, delete on public.memory_submissions_v2 from anon, authenticated;
revoke insert, update, delete on public.memory_review_logs_v2 from anon, authenticated;
revoke insert, update, delete on public.question_learning_preferences_v2 from anon, authenticated;

create or replace function public.reserve_memory_submission_v2(
  p_user_id uuid,
  p_submission_id uuid,
  p_question_id uuid,
  p_session_id uuid,
  p_event_type text,
  p_expected_state_version bigint default null
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare v_row public.memory_submissions_v2; v_question public.questions;
begin
  if auth.role() <> 'service_role' then raise exception 'SERVICE_ROLE_REQUIRED'; end if;
  if p_event_type not in ('initial','review','voluntary','pass') then raise exception 'INVALID_EVENT_TYPE'; end if;
  select * into v_question from public.questions
   where id=p_question_id and user_id=p_user_id and type='multiple_choice'
     and exists (
       select 1 from public.study_materials sm
       where sm.id=v_question.material_id and sm.user_id=p_user_id and sm.status='completed'
     );
  if not found or jsonb_typeof(v_question.options) <> 'array'
     or jsonb_array_length(v_question.options) < 2 or btrim(v_question.answer) = ''
     or not (v_question.options ? v_question.answer) then
    raise exception 'QUESTION_NOT_ELIGIBLE';
  end if;
  insert into public.memory_submissions_v2
    (submission_id,user_id,question_id,session_id,event_type,reviewed_at,expected_state_version)
  values (p_submission_id,p_user_id,p_question_id,p_session_id,p_event_type,transaction_timestamp(),p_expected_state_version)
  on conflict (submission_id) do update
    set duplicate_count=public.memory_submissions_v2.duplicate_count+1,
        updated_at=transaction_timestamp()
  returning * into v_row;
  if v_row.user_id <> p_user_id or v_row.question_id <> p_question_id then
    raise exception 'SUBMISSION_ID_CONFLICT';
  end if;
  return jsonb_build_object(
    'submission_id',v_row.submission_id,'status',v_row.status,
    'reviewed_at',v_row.reviewed_at,'response',v_row.response,
    'duplicate',v_row.duplicate_count>0
  );
end $$;

create or replace function public.refresh_memory_submission_v2(
  p_user_id uuid,
  p_submission_id uuid
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare v_submission public.memory_submissions_v2; v_state public.question_memory_states_v2;
begin
  if auth.role() <> 'service_role' then raise exception 'SERVICE_ROLE_REQUIRED'; end if;
  select * into v_submission from public.memory_submissions_v2
   where submission_id=p_submission_id and user_id=p_user_id and status='pending' for update;
  if not found then raise exception 'PENDING_SUBMISSION_NOT_FOUND'; end if;
  select * into v_state from public.question_memory_states_v2
   where user_id=p_user_id and question_id=v_submission.question_id for update;
  update public.memory_submissions_v2 set
    reviewed_at=transaction_timestamp(),
    expected_state_version=v_state.state_version,
    event_type=case
      when v_submission.event_type='pass' then 'pass'
      when v_state.id is null then 'initial'
      else 'review'
    end,
    updated_at=transaction_timestamp()
  where id=v_submission.id
  returning * into v_submission;
  return jsonb_build_object(
    'reviewed_at',v_submission.reviewed_at,
    'state',case when v_state.id is null then null else to_jsonb(v_state) end
  );
end $$;
create or replace function public.finalize_memory_submission_v2(
  p_user_id uuid,
  p_submission_id uuid,
  p_selected_answer text,
  p_is_correct boolean,
  p_response_time_ms integer,
  p_retry_count integer,
  p_hint_level integer,
  p_rating smallint,
  p_pass_action text,
  p_candidate jsonb
) returns jsonb
language plpgsql security definer set search_path = public
as $$
declare
  v_submission public.memory_submissions_v2;
  v_question public.questions;
  v_current public.question_memory_states_v2;
  v_state_id uuid;
  v_response jsonb;
  v_schedule_neutral boolean;
  v_effective_event text;
begin
  if auth.role() <> 'service_role' then raise exception 'SERVICE_ROLE_REQUIRED'; end if;
  select * into v_submission from public.memory_submissions_v2
   where submission_id=p_submission_id and user_id=p_user_id for update;
  if not found then raise exception 'SUBMISSION_NOT_RESERVED'; end if;
  if v_submission.status='completed' then return v_submission.response; end if;
  select * into v_question from public.questions
   where id=v_submission.question_id and user_id=p_user_id and type='multiple_choice'
     and exists (
       select 1 from public.study_materials sm
       where sm.id=v_question.material_id and sm.user_id=p_user_id and sm.status='completed'
     );
  if not found then raise exception 'QUESTION_NOT_ELIGIBLE'; end if;
  select * into v_current from public.question_memory_states_v2
   where user_id=p_user_id and question_id=v_submission.question_id for update;
  if v_submission.expected_state_version is distinct from v_current.state_version then
    raise exception 'STATE_VERSION_CONFLICT';
  end if;
  v_effective_event := case
    when v_submission.event_type='review' and v_current.due_at > v_submission.reviewed_at then 'voluntary'
    else v_submission.event_type end;
  v_schedule_neutral := v_effective_event in ('voluntary','pass');
  if v_submission.event_type='pass' and p_rating is not null then raise exception 'PASS_HAS_RATING'; end if;
  if v_submission.event_type<>'pass' and p_rating not in (1,2,3) then raise exception 'INVALID_RATING'; end if;
  if not v_schedule_neutral then
    if (p_candidate->>'last_review')::timestamptz <> v_submission.reviewed_at then raise exception 'REVIEW_TIME_CONFLICT'; end if;
    if (p_candidate->>'due')::timestamptz < v_submission.reviewed_at then raise exception 'INVALID_DUE_AT'; end if;
    insert into public.question_memory_states_v2
      (user_id,question_id,state,due_at,last_reviewed_at,stability,difficulty,elapsed_days,scheduled_days,reps,lapses,learning_steps,last_rating,engine_version,algorithm_version,parameter_version,state_version)
    values
      (p_user_id,v_submission.question_id,p_candidate->>'state',(p_candidate->>'due')::timestamptz,v_submission.reviewed_at,
       (p_candidate->>'stability')::double precision,(p_candidate->>'difficulty')::double precision,
       (p_candidate->>'elapsed_days')::integer,(p_candidate->>'scheduled_days')::integer,
       (p_candidate->>'reps')::integer,(p_candidate->>'lapses')::integer,
       coalesce((p_candidate->>'learning_steps')::integer,0),p_rating,'fsrs_v2','fsrs-6','fsrs-6-default-v1',coalesce(v_current.state_version,0)+1)
    on conflict (user_id,question_id) do update set
      state=excluded.state,due_at=excluded.due_at,last_reviewed_at=excluded.last_reviewed_at,
      stability=excluded.stability,difficulty=excluded.difficulty,elapsed_days=excluded.elapsed_days,
      scheduled_days=excluded.scheduled_days,reps=excluded.reps,lapses=excluded.lapses,
      learning_steps=excluded.learning_steps,last_rating=excluded.last_rating,
      engine_version=excluded.engine_version,algorithm_version=excluded.algorithm_version,
      parameter_version=excluded.parameter_version,state_version=excluded.state_version,updated_at=transaction_timestamp()
    returning id into v_state_id;
  else
    v_state_id := v_current.id;
  end if;
  if v_submission.event_type='pass' and p_pass_action in ('deferred','known','out_of_scope','quality_issue') then
    insert into public.question_learning_preferences_v2(user_id,question_id,status,reason)
    values(p_user_id,v_submission.question_id,p_pass_action,p_pass_action)
    on conflict(user_id,question_id) do update set status=excluded.status,reason=excluded.reason,updated_at=transaction_timestamp();
  end if;
  insert into public.quiz_attempts(user_id,material_id,question_id,selected_answer,is_correct,response_time_ms,success_attempt,retry_count,hint_used,hint_level,attempted_at)
  values(p_user_id,v_question.material_id,v_question.id,coalesce(p_selected_answer,''),coalesce(p_is_correct,false),greatest(p_response_time_ms,0),coalesce(p_is_correct,false),greatest(p_retry_count,0),p_hint_level>0,greatest(least(p_hint_level,2),0),v_submission.reviewed_at);
  insert into public.memory_review_logs_v2
    (submission_id,user_id,question_id,memory_state_id,event_type,rating,pass_action,previous_state,next_state,previous_due_at,next_due_at,elapsed_days,scheduled_days,response_time_ms,retry_count,hint_level,is_correct,engine_version,algorithm_version,parameter_version)
  values
    (p_submission_id,p_user_id,v_question.id,v_state_id,v_effective_event,p_rating,p_pass_action,v_current.state,
     case when v_schedule_neutral then v_current.state else p_candidate->>'state' end,v_current.due_at,
     case when v_schedule_neutral then v_current.due_at else (p_candidate->>'due')::timestamptz end,
     coalesce((p_candidate->>'elapsed_days')::integer,0),coalesce((p_candidate->>'scheduled_days')::integer,0),greatest(p_response_time_ms,0),greatest(p_retry_count,0),greatest(least(p_hint_level,2),0),p_is_correct,'fsrs_v2','fsrs-6','fsrs-6-default-v1');
  v_response := jsonb_build_object(
    'submission_id',p_submission_id,'reviewed_at',v_submission.reviewed_at,'duplicate',false,
    'schedule_changed',not v_schedule_neutral,'rating',p_rating,'pass_action',p_pass_action,
    'state',case when v_schedule_neutral then v_current.state else p_candidate->>'state' end,
    'due_at',case when v_schedule_neutral then v_current.due_at else (p_candidate->>'due')::timestamptz end,
    'stability',case when v_schedule_neutral then v_current.stability else (p_candidate->>'stability')::double precision end,
    'difficulty',case when v_schedule_neutral then v_current.difficulty else (p_candidate->>'difficulty')::double precision end,
    'state_version',case when v_schedule_neutral then v_current.state_version else coalesce(v_current.state_version,0)+1 end
  );
  update public.memory_submissions_v2 set status='completed',response=v_response,updated_at=transaction_timestamp()
   where id=v_submission.id;
  return v_response;
end $$;

create or replace function public.get_due_reviews_v2(p_limit integer default 20, p_count_only boolean default false)
returns jsonb language sql security invoker set search_path=public
as $$
  with eligible as (
    select qms.id as memory_state_id,qms.question_id,qms.due_at,qms.stability,qms.difficulty,qms.state,q.material_id,q.concept_id,
      q.section_id,q.type,q.question_text,q.options,q.answer,q.explanation,q.evidence,q.difficulty as question_difficulty,q.order_index,
      coalesce(ms.memory_score,0) as legacy_memory_score
    from public.question_memory_states_v2 qms
    join public.questions q on q.id=qms.question_id and q.user_id=qms.user_id
    join public.study_materials sm on sm.id=q.material_id and sm.user_id=qms.user_id and sm.status='completed'
    left join public.question_learning_preferences_v2 pref on pref.user_id=qms.user_id and pref.question_id=qms.question_id
    left join public.memory_states ms on ms.user_id=qms.user_id and ms.material_id=q.material_id and ms.concept_id=q.concept_id
    where qms.user_id=auth.uid() and qms.due_at<=transaction_timestamp()
      and q.type='multiple_choice' and jsonb_typeof(q.options)='array' and jsonb_array_length(q.options)>=2
      and btrim(q.answer)<>'' and q.options ? q.answer and coalesce(pref.status,'active')='active'
    order by qms.due_at,qms.stability,qms.question_id
  )
  select jsonb_build_object('total_count',(select count(*) from eligible),'items',
    case when p_count_only then '[]'::jsonb else coalesce((select jsonb_agg(to_jsonb(x)) from (select * from eligible limit greatest(1,least(p_limit,100))) x),'[]'::jsonb) end)
$$;

revoke all on function public.refresh_memory_submission_v2(uuid,uuid) from public, anon, authenticated;
grant execute on function public.refresh_memory_submission_v2(uuid,uuid) to service_role;
revoke all on function public.reserve_memory_submission_v2(uuid,uuid,uuid,uuid,text,bigint) from public, anon, authenticated;
revoke all on function public.finalize_memory_submission_v2(uuid,uuid,text,boolean,integer,integer,integer,smallint,text,jsonb) from public, anon, authenticated;
grant execute on function public.reserve_memory_submission_v2(uuid,uuid,uuid,uuid,text,bigint) to service_role;
grant execute on function public.finalize_memory_submission_v2(uuid,uuid,text,boolean,integer,integer,integer,smallint,text,jsonb) to service_role;
grant execute on function public.get_due_reviews_v2(integer,boolean) to authenticated;

-- No backfill is performed. Existing v1 due dates remain the compatibility source until first v2 submission.
-- Rollback/fallback: disable the feature flag first. Preserve tables/logs for audit; do not drop data automatically.
-- Pre-apply verification: confirm questions options is jsonb and quiz_attempts V1.1 metadata columns exist.
