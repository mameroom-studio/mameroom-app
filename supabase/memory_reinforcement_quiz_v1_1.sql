-- Memory Reinforcement Quiz System V1.1
-- Adds optional attempt metadata for retry/hint-aware memory scoring.

alter table public.quiz_attempts
  add column if not exists success_attempt boolean not null default false,
  add column if not exists retry_count integer not null default 0 check (retry_count >= 0),
  add column if not exists hint_used boolean not null default false,
  add column if not exists hint_level integer not null default 0 check (hint_level between 0 and 2);

create index if not exists quiz_attempts_user_question_attempt_idx
  on public.quiz_attempts (user_id, question_id, attempted_at desc);
