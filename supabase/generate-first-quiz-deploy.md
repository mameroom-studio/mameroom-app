# generate-first-quiz Deployment

This Edge Function runs AI2 only: it generates the first 10 quiz questions from saved `concepts`.
It must be deployed server-side because OpenAI credentials must never be bundled into the Flutter app.

## Commands

Link the local project to Supabase:

```bash
supabase login
supabase link --project-ref zglfjvnjnopilhikkxum
```

Set OpenAI secrets for Edge Functions only:

```bash
supabase secrets set OPENAI_API_KEY=your-openai-api-key
supabase secrets set OPENAI_MODEL=gpt-4.1-mini
```

Deploy the function:

```bash
supabase functions deploy generate-first-quiz
```

## Function Contract

Request body:

```json
{
  "materialId": "study_material_uuid"
}
```

Expected success response:

```json
{
  "materialId": "study_material_uuid",
  "status": "completed",
  "questionCount": 10,
  "usedCache": false,
  "message": "First quiz generated and saved."
}
```

## Verification Checklist

- Runs only when `study_materials.status = concepts_completed`, unless the material already has an initial quiz.
- Reads concepts from `concepts` by `materialId`.
- Generates exactly 10 initial questions: 5 `multiple_choice`, 3 `ox`, 2 `fill_blank`.
- Saves every question to `questions` with `evidence`, `concept_id`, `section_id`, `difficulty`, `type`, `answer`, and `explanation`.
- Updates status to `questions_generating` while generating.
- Updates status to `completed` after questions are stored.
- If the same `materialId` already has 10 initial questions, it returns them as reused without calling OpenAI.
- If the same `source_hash` already has 10 initial questions, it copies those questions for the new material without calling OpenAI.
- On runtime failure after `materialId` is known, it updates `study_materials.status` to `failed` and stores `analysis_error`.
- Quiz solving and memory scoring are not implemented here.
- Do not use or expose a service role key in Flutter.
- Do not store `OPENAI_API_KEY` or `OPENAI_MODEL` in Flutter `.env` files.