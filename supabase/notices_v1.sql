-- Mameroom Notices v1. Service-role manages notices; users read active rows.
begin;
create table if not exists public.notices (
  id uuid primary key default gen_random_uuid(),
  title text not null check(char_length(btrim(title)) between 1 and 160),
  content text not null check(char_length(btrim(content)) between 1 and 20000),
  notice_type text not null default 'GENERAL' check(
    notice_type in ('GENERAL','IMPORTANT','MAINTENANCE','EVENT','UPDATE')
  ),
  is_pinned boolean not null default false,
  is_published boolean not null default false,
  published_at timestamptz,
  starts_at timestamptz,
  ends_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null,
  check(starts_at is null or ends_at is null or starts_at<ends_at)
);
create index if not exists notices_visibility_idx
  on public.notices(is_published,is_pinned desc,published_at desc,created_at desc);
create index if not exists notices_window_idx on public.notices(starts_at,ends_at);

alter table public.notices enable row level security;
revoke all on public.notices from anon,authenticated;
grant select on public.notices to authenticated;
drop policy if exists "Authenticated users read active notices" on public.notices;
create policy "Authenticated users read active notices" on public.notices
  for select to authenticated using(
    is_published
    and published_at is not null and published_at<=now()
    and (starts_at is null or starts_at<=now())
    and (ends_at is null or ends_at>now())
  );
comment on table public.notices is
  'Service-role managed notices. No application admin identity exists in v1.';
commit;

-- Manual rollback: revoke SELECT, archive exported rows, then drop notices.
