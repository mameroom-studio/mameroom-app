# AI Memory Coach

Android-first Flutter MVP skeleton for an AI memorization coach.

## Setup

1. Install Flutter stable.
2. From this project root, generate the Android platform wrapper if it is not present:

```bash
flutter create --platforms=android .
```

3. Create a Supabase project and enable Email Auth.
4. Copy `.env.example` to `.env` and fill only `SUPABASE_URL` and `SUPABASE_PUBLISHABLE_KEY`.
5. Run `supabase/study_materials.sql` and `supabase/storage_buckets.sql` in the Supabase SQL editor.
6. Deploy the `extract-core-concepts` Edge Function. See `supabase/extract-core-concepts-deploy.md` for the full checklist:

```bash
supabase functions deploy extract-core-concepts
```

7. Deploy the `generate-first-quiz` Edge Function. See `supabase/generate-first-quiz-deploy.md` for the full checklist:

```bash
supabase functions deploy generate-first-quiz
```

8. Configure OpenAI only as Supabase Edge Function secrets:

```bash
supabase secrets set OPENAI_API_KEY=your-openai-api-key
supabase secrets set OPENAI_MODEL=gpt-4.1-mini
```

9. Run `flutter pub get`.
10. Run `flutter run -d android`.
11. Test connection by creating an account or signing in. Success lands on the Library screen and shows the signed-in email.

## Architecture Rules

- Feature-first Clean Architecture.
- Presentation depends on Riverpod providers and use cases.
- Use cases depend on domain repository contracts.
- Repositories and data sources hide Supabase and Edge Function details.
- Original PDF/image uploads use Supabase Storage from the upload data source.
- Study material rows are inserted through the upload repository/data source.
- The Flutter app never stores or calls OpenAI API keys.
- AI1 concept extraction is performed only by the Supabase Edge Function named `extract-core-concepts`.
- The Flutter app sends only `materialId` to `extract-core-concepts`; OpenAI calls, model selection, and concept persistence run server-side.
- Store `OPENAI_API_KEY` and optional `OPENAI_MODEL` only as Supabase Edge Function secrets.
- Never store service role keys, OpenAI keys, or other private server credentials in Flutter `.env` files.
- Quiz solving must use stored questions and local algorithms only. No AI call during quiz solving.
- AI1 success stores `study_materials.status = concepts_completed`; it does not use `generating`.
- AI2 first quiz generation is performed only by the Supabase Edge Function named `generate-first-quiz`.
- AI2 first quiz success stores `study_materials.status = completed` after `questions_generating`.
- `.env` is bundled into Flutter builds, so store only public client configuration such as the Supabase publishable key.