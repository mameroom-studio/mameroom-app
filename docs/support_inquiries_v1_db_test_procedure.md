# Support inquiries v1 — staging DB test procedure

Run only after the migration in a disposable local/staging clone. Do not run automatically in production. Use two existing `auth.users.id` values (`USER_A`, `USER_B`) and finish with `ROLLBACK`.

## Session setup

```sql
begin;
set local role authenticated;
select set_config('request.jwt.claim.sub', 'USER_A', true);
```

## Normal create and 60-second limit

```sql
select * from public.create_support_inquiry(
  'BUG_REPORT','정상 문의 제목','정상 문의 본문은 열 자 이상입니다.'
); -- SUCCESS; save inquiry_id as INQUIRY_A
select * from public.create_support_inquiry(
  'QUIZ_STUDY','두 번째 문의 제목','첫 문의 직후의 두 번째 문의 본문입니다.'
); -- RATE_LIMITED
```

## Duplicate

As the SQL-editor owner, `reset role`, move `INQUIRY_A.created_at` to `now()-interval '61 seconds'`, restore the authenticated USER_A claim, and resubmit the exact category/title/content. Expect `DUPLICATE_INQUIRY`.

## Daily five

As the SQL-editor owner, insert enough distinct USER_A rows dated today and older than 60 seconds so today's total is five. Restore authenticated USER_A and call the RPC with new content. Expect `DAILY_LIMIT_EXCEEDED`.

## User isolation and direct writes

```sql
set local role authenticated;
select set_config('request.jwt.claim.sub', 'USER_B', true);
select count(*) from public.support_inquiries where user_id='USER_A'; -- 0
select count(*) from public.support_replies where inquiry_id='INQUIRY_A'; -- 0
```

In separate savepoints, attempt direct INSERT, UPDATE and DELETE as USER_B/authenticated. Each must fail with permission denied. Roll back each savepoint so an expected error does not abort the complete test transaction.

## Function privilege audit

```sql
select
 has_function_privilege('anon','public.answer_support_inquiry(uuid,text,uuid)','EXECUTE') anon_can,
 has_function_privilege('authenticated','public.answer_support_inquiry(uuid,text,uuid)','EXECUTE') authenticated_can,
 has_function_privilege('service_role','public.answer_support_inquiry(uuid,text,uuid)','EXECUTE') service_can;
-- expected: false, false, true
```

## Operator answer and rollback

```sql
reset role;
set local role service_role;
select public.answer_support_inquiry(
  'INQUIRY_A','운영자가 등록한 정상 답변입니다.',null
);
reset role;
select i.status,i.answered_at,r.content
from public.support_inquiries i join public.support_replies r on r.inquiry_id=i.id
where i.id='INQUIRY_A'; -- ANSWERED + one reply
```

Snapshot the inquiry/reply rows, then call `answer_support_inquiry(INQUIRY_A, '   ', null)` inside a savepoint. It must raise `invalid_reply`. Roll back to the savepoint and compare status, answered_at, content and both updated_at values to the snapshot; all must be unchanged.

```sql
rollback;
```

Also test a nonexistent inquiry UUID: `answer_support_inquiry` must raise `inquiry_not_found` and create no reply. Material linkage is intentionally disabled: any non-null `p_related_material_id` must return `INVALID_RELATED_MATERIAL` until production PK and ownership columns are approved.