-- Run this in the Supabase SQL editor.
-- Creates the private materials bucket and policies for authenticated users.

insert into storage.buckets (id, name, public)
values ('materials', 'materials', false)
on conflict (id) do nothing;

drop policy if exists "Users can upload own material files" on storage.objects;
drop policy if exists "Users can read own material files" on storage.objects;

create policy "Users can upload own material files"
  on storage.objects
  for insert
  to authenticated
  with check (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "Users can read own material files"
  on storage.objects
  for select
  to authenticated
  using (
    bucket_id = 'materials'
    and (storage.foldername(name))[1] = auth.uid()::text
  );