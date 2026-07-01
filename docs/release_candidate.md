# MVP Release Candidate

## Freeze Scope
- New feature development is frozen.
- Included MVP areas: Auth, Library, Upload, Analysis AI1, First Quiz AI2, Quiz, Memory Engine, Review Today, M-Coin, My Room LV1, and Streak.
- Excluded areas remain frozen: payment, social, ranking, real-time chat, iOS, web, and admin features.

## Code Freeze Cleanup
- Removed unused dependencies from `pubspec.yaml`: `cupertino_icons`, `equatable`, `fl_chart`.
- Removed unused Progress placeholder feature.
- Removed obsolete gamification CoinBalance stubs.
- Simplified lint configuration to Flutter default lints.
- Replaced deprecated `withOpacity` usage in current source.

## Verification Status
- Static source search found no OpenAI key, service role key, or forbidden AI invocation in quiz, review, coins, room, streak, or library flows.
- Supabase SDK usage remains in data/datasources.
- `flutter analyze` could not be completed in this workspace because the Flutter command is not available in PATH.

## Required Before Release
- Install or expose Flutter stable in PATH.
- Run `flutter pub get`.
- Run `flutter analyze`.
- Run Android debug build on emulator or device.
- Apply Supabase SQL on staging.
- Confirm storage bucket and RLS policies.
- Deploy Edge Functions and configure OpenAI key only as Supabase secret.
- Execute Android smoke test checklist.

## Release Decision
- Current state: Release Candidate prepared, but not releasable until Flutter analyze and Android build verification pass in a Flutter-enabled environment.
