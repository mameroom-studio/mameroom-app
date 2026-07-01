# extract-core-concepts Deployment

This Edge Function runs AI1 only: it extracts up to 50 core concepts and stores them in `concepts`.
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
supabase functions deploy extract-core-concepts
```

Optional local serve:

```bash
supabase functions serve extract-core-concepts --env-file ./supabase/.env.local
```

## Function Contract

Request body from Flutter:

```json
{
  "materialId": "study_material_uuid"
}
```

Expected success response:

```json
{
  "materialId": "study_material_uuid",
  "status": "concepts_completed",
  "conceptCount": 10,
  "usedCache": false,
  "message": "Core concepts extracted by extract-core-concepts."
}
```

## Verification Checklist

- Flutter sends only `materialId` to `extract-core-concepts`.
- The function reads `study_materials.raw_text` or reuses `study_materials.structured_text`.
- The function updates `study_materials.status` to `extracting`, then `analyzing`, then `concepts_completed`.
- If a `concepts_completed` or `completed` row with the same `file_hash` exists, the function copies cached concepts and does not call OpenAI again.
- If another unfinished row with the same `file_hash` exists, the function blocks re-analysis and marks the current row as `failed`.
- On runtime failure after `materialId` is known, the function updates `study_materials.status` to `failed` and stores `analysis_error`.
- AI1 stores extracted concepts in the `concepts` table with `user_id`, `material_id`, `name`, `description`, `importance`, and `evidence`.
- AI2 question generation is not implemented here. Future AI2 status flow is `questions_generating -> completed`.
- Do not use or expose a service role key in Flutter.
- Do not store `OPENAI_API_KEY` or `OPENAI_MODEL` in Flutter `.env` files.

## Manual Invoke Example

Use a real authenticated user JWT for `USER_ACCESS_TOKEN`.

```bash
curl -i \
  -X POST "https://zglfjvnjnopilhikkxum.supabase.co/functions/v1/extract-core-concepts" \
  -H "Authorization: Bearer USER_ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"materialId":"study_material_uuid"}'
```