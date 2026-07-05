-- Question Policy V1.1: remove OX and add short_answer.
begin;

delete from public.questions
where type = 'ox';

alter table public.questions
  drop constraint if exists questions_type_check;

alter table public.questions
  add constraint questions_type_check
  check (type in ('short_answer', 'multiple_choice', 'fill_blank'));

commit;
