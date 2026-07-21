# Memory Engine v2 local implementation

Status: local only. The production migration, backfill, and Edge deployment have not been run.

## Version contract

- Engine: `fsrs_v2`
- Algorithm: `fsrs-6`
- Parameters: `fsrs-6-default-v1`
- Scheduler: `ts-fsrs@5.4.1`, MIT
- Desired retention: Edge secret/config `MEMORY_ENGINE_DESIRED_RETENTION`, default `0.90`

Parameter optimization is prohibited until at least 10,000 valid review logs and
1,000 real learners exist, and still requires PM approval.

## Feature flag

Flutter defaults off and requires both:

```text
--dart-define=MEMORY_ENGINE_V2_ENABLED=true
MEMORY_ENGINE_V2_ALLOWLIST=<user UUIDs or *>
```

The Edge Function independently requires:

```text
MEMORY_ENGINE_V2_ENABLED=true
MEMORY_ENGINE_V2_ALLOWLIST=<user UUIDs or *>
MEMORY_ENGINE_DESIRED_RETENTION=0.90
```

The Edge allowlist is authoritative. A disabled client continues to use legacy v1.
Do not automatically call v1 after an ambiguous v2 network failure; retry the same
`submission_id` so the confirmed response is returned idempotently.

## Transaction boundary

`reserve_memory_submission_v2` records the PostgreSQL `transaction_timestamp()`.
The Edge scheduler uses that exact `reviewed_at`. `finalize_memory_submission_v2`
locks the reservation and current card, verifies `state_version`, and atomically
writes the attempt, card, review log, preference, and stored response.

PASS and early voluntary study are schedule-neutral. They can write an attempt/log
but cannot change stability, difficulty, reps, lapses, or due date.

## Existing-user transition

No backfill is performed. Legacy concept-level state stays intact. A question gets
its first v2 card on its next eligible submission. Legacy due dates remain available
to v1 until that transition; FSRS values are not reverse-engineered or copied across
questions sharing a concept.

## Question lifecycle limitation

The current `questions` table has no active or soft-delete field. V2 therefore
requires row existence, an owned completed material, multiple-choice type, and valid
options/answer. Existing physical deletion cascades to v2 card rows. Adding soft
delete is intentionally deferred because its product-wide query impact needs a
separate PM decision.

## Pre-production order

1. Apply legacy `memory_reinforcement_quiz_v1_1.sql` if its attempt metadata is absent.
2. Apply `202607210001_memory_engine_v2_additive.sql` to a disposable/local DB.
3. Run RLS, direct-write rejection, RPC idempotency, CAS, rollback, and due tests.
4. Deploy the Edge Function to staging only and configure an explicit allowlist.
5. Run shadow comparison and monitor failures without changing the existing memory UI.
6. Obtain separate approval before production migration, deployment, or activation.

Rollback means disabling both feature flags. Do not drop v2 audit data automatically.


## Activation blockers found during local verification

Keep both v2 feature flags disabled until these are resolved and tested against a
disposable database:

- The legacy review-completion and review-streak coin RPC validates a completed
  `review_schedules.id`. V2 review items use a
  `question_memory_states_v2.id`, so the existing completion reward call is not
  compatible. Do not bypass that server validation or mint coins directly. A
  separately reviewed v2 session/reward transaction contract is required.
- Existing users that only have legacy `review_schedules` and no v2 cards still
  need a reviewed bridge query/session policy. The current v2 due RPC intentionally
  returns only v2 cards; enabling it prematurely could hide legacy due work.
- SQL contract tests inspect migration text. PostgreSQL execution, rollback,
  RLS isolation, concurrent CAS, and idempotent retry behavior remain unverified
  because the local Docker/Supabase database was unavailable.

## Local verification completed

- Deno check: Edge entrypoint and FSRS tests passed.
- Deno tests: 3 passed (rating policy, schedule-neutral PASS, repeated Good).
- Flutter targeted migration/model tests: 6 passed.
- Flutter review/home/study regression tests: 20 passed.
- Full `flutter analyze`: no issues.
- Flutter Web debug build: succeeded.
- Local Supabase runtime: not run; Docker daemon was unavailable.
