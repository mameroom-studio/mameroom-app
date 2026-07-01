# Android MVP Smoke Test Checklist

## Environment
- Flutter stable is installed and available in PATH.
- `flutter pub get` succeeds.
- `flutter analyze` has no errors.
- Android emulator or physical Android device is available.
- `.env` contains only Supabase URL and publishable key.
- No service role key or OpenAI key exists in Flutter assets or source.

## Supabase
- Database migrations in `supabase/study_materials.sql` are applied.
- `materials` storage bucket exists.
- Row level security policies allow the signed-in user to access only own rows.
- DB functions exist: `award_m_coin`, `purchase_room_item`, `record_daily_streak`.
- Edge Function secrets contain `OPENAI_API_KEY` on Supabase only.
- Edge Functions deployed: `extract-core-concepts`, `generate-first-quiz`.

## App Flow
- App starts at LoginPage when signed out.
- App starts at LibraryPage when a valid session exists.
- Signup, login, logout, and session restore work.
- Library empty state and dashboard cards render.
- UploadPage validates PDF, image, camera, text, type, and size states.
- Upload success creates the material and opens AnalysisPage.
- Analysis status updates and cache reuse work.
- Completed material opens QuizPage.
- Quiz runs with no AI or Edge Function call.
- QuizResultPage shows score, response time, memory, review schedule, and coins.
- ReviewPage shows due review items and updates schedules after completion.
- RoomPage and ShopPage render and purchase through DB function.
- Streak updates after first learning completion of the day.

## Negative Paths
- Network disconnected during login shows an error state.
- Storage upload failure keeps the user on UploadPage or shows retry guidance.
- Edge Function failure marks material as failed.
- Missing questions for completed material shows an empty/error state.
- Insufficient coin balance blocks shop purchase.
