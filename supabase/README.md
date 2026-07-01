# Supabase Setup

## Required project settings

1. Create a Supabase project.
2. Enable email Auth in Authentication > Providers > Email.
3. Copy the project URL into `SUPABASE_URL`.
4. Copy the publishable key into `SUPABASE_PUBLISHABLE_KEY`.
5. Do not put the service role key in the Flutter app.
6. Do not put OpenAI keys in the Flutter app.

## Database and Storage

Run these files in the Supabase SQL editor:

1. `study_materials.sql`
2. `storage_buckets.sql`

The Android MVP upload flow stores original PDF/image files in the private `materials` bucket and inserts an `uploaded` row into `study_materials`.

Text paste materials create a `study_materials` row only. Text file storage and AI analysis are intentionally not implemented in this step.