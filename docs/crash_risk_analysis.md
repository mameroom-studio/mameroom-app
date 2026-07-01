# MVP Crash Risk Analysis

## High Risk
- Flutter CLI or Android SDK missing in release environment can block build verification.
- Missing `.env` asset can crash or block Supabase initialization.
- Supabase schema not migrated can break runtime queries and RPC calls.
- RLS or policy mismatch can produce empty data or permission errors that look like app failures.
- Storage bucket missing can fail upload after local validation succeeds.
- Edge Function timeout or malformed response can leave materials stuck unless failed status is handled.

## Medium Risk
- File picker or camera permission cancellation can return null values.
- Large PDF or image files can cause memory pressure during hash or extraction preparation.
- Nullable joined rows in quiz, review, room, or wallet data can break model parsing.
- Duplicate reward, streak, or purchase calls can cause constraint or idempotency issues.
- Timezone differences can affect today review and daily streak calculation.
- Provider invalidation during route changes can show stale loading states.

## Low Risk
- Missing seeded room items leaves ShopPage empty.
- Unsupported question type from DB can break quiz rendering.
- Missing evidence or explanation can weaken result screen quality.
- Network loss after answer submission can desync local progress from saved attempts.

## Mitigation Before Release
- Run full migration on staging Supabase before app build testing.
- Verify `.env` has no OpenAI or service role key.
- Run `flutter analyze` and at least one Android debug build on a machine with Flutter installed.
- Test every negative path in the smoke checklist.
- Confirm all coin and purchase mutations are routed through DB functions.
