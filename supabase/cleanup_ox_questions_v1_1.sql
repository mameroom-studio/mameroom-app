-- Existing OX cleanup for test databases.
select count(*) as ox_questions_before_cleanup
from public.questions
where type = 'ox';

delete from public.questions
where type = 'ox'
returning id, material_id, concept_id, question_text;

select count(*) as ox_questions_after_cleanup
from public.questions
where type = 'ox';
