-- Non-destructive Study material deletion policies.
-- Existing rows, columns, foreign keys, and data are not changed.

alter table public.study_materials enable row level security;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'public'
      and tablename = 'study_materials'
      and cmd = 'DELETE'
      and (
        policyname = 'Users can delete own study materials'
        or qual ilike '%auth.uid()%user_id%'
      )
  ) then
    create policy "Users can delete own study materials"
      on public.study_materials
      for delete
      to authenticated
      using (auth.uid() = user_id);
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd = 'DELETE'
      and policyname = 'Users can delete own material files'
  ) then
    create policy "Users can delete own material files"
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'materials'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end
$$;

do $$
begin
  if not exists (
    select 1
    from pg_policies
    where schemaname = 'storage'
      and tablename = 'objects'
      and cmd = 'DELETE'
      and policyname = 'Users can delete own PDF analysis files'
  ) then
    create policy "Users can delete own PDF analysis files"
      on storage.objects
      for delete
      to authenticated
      using (
        bucket_id = 'pdf_uploads'
        and (storage.foldername(name))[1] = auth.uid()::text
      );
  end if;
end
$$;
