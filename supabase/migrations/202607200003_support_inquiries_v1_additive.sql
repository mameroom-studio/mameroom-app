-- Mameroom text-only support MVP. Additive; review preflight before production.
create extension if not exists pgcrypto with schema extensions;

create table if not exists public.support_inquiries (
  id uuid primary key default extensions.gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  category text not null check (category in ('MATERIAL_ANALYSIS','QUIZ_STUDY','PAYMENT_QUOTA','ACCOUNT_PROFILE','FRIEND_NOTIFICATION','BUG_REPORT','SUGGESTION_OTHER')),
  title text not null check (char_length(btrim(title)) between 5 and 80),
  content text not null check (char_length(btrim(content)) between 10 and 2000),
  status text not null default 'RECEIVED' check (status in ('RECEIVED','IN_REVIEW','ANSWERED','CLOSED')),
  app_version text check (app_version is null or char_length(app_version) <= 32),
  build_number text check (build_number is null or char_length(build_number) <= 32),
  platform text check (platform is null or char_length(platform) <= 32),
  os_version text check (os_version is null or char_length(os_version) <= 128),
  locale text check (locale is null or char_length(locale) <= 32),
  current_route text check (current_route is null or char_length(current_route) <= 256),
  -- No FK until the production study_materials contract is verified.
  related_material_id uuid null,
  metadata jsonb not null default '{}'::jsonb check (jsonb_typeof(metadata) = 'object'),
  answered_at timestamptz,
  closed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.support_replies (
  id uuid primary key default extensions.gen_random_uuid(),
  inquiry_id uuid not null references public.support_inquiries(id) on delete cascade,
  -- No operator identity FK until its production contract is verified.
  responder_id uuid null,
  content text not null check (char_length(btrim(content)) between 1 and 4000),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (inquiry_id)
);

create index if not exists support_inquiries_user_created_idx on public.support_inquiries(user_id, created_at desc, id desc);
create index if not exists support_inquiries_status_created_idx on public.support_inquiries(status, created_at desc);
create index if not exists support_replies_inquiry_created_idx on public.support_replies(inquiry_id, created_at desc);

create or replace function public.support_touch_updated_at() returns trigger language plpgsql set search_path = pg_catalog, public, pg_temp as $$ begin new.updated_at = now(); return new; end $$;
drop trigger if exists support_inquiries_touch_updated_at on public.support_inquiries;
create trigger support_inquiries_touch_updated_at before update on public.support_inquiries for each row execute function public.support_touch_updated_at();
drop trigger if exists support_replies_touch_updated_at on public.support_replies;
create trigger support_replies_touch_updated_at before update on public.support_replies for each row execute function public.support_touch_updated_at();

alter table public.support_inquiries enable row level security;
alter table public.support_replies enable row level security;

drop policy if exists "Users read own support inquiries" on public.support_inquiries;
create policy "Users read own support inquiries" on public.support_inquiries for select to authenticated using (user_id = auth.uid());
drop policy if exists "Users read replies to own inquiries" on public.support_replies;
create policy "Users read replies to own inquiries" on public.support_replies for select to authenticated using (exists (select 1 from public.support_inquiries i where i.id = inquiry_id and i.user_id = auth.uid()));

revoke all on public.support_inquiries, public.support_replies from anon;
revoke insert, update, delete on public.support_inquiries, public.support_replies from authenticated;
grant select on public.support_inquiries, public.support_replies to authenticated;

create or replace function public.create_support_inquiry(
  p_category text, p_title text, p_content text,
  p_app_version text default null, p_build_number text default null,
  p_platform text default null, p_os_version text default null,
  p_locale text default null, p_current_route text default null,
  p_related_material_id uuid default null
) returns table(result_code text, inquiry_id uuid)
language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
declare
  v_user uuid := auth.uid(); v_id uuid; v_title text := btrim(p_title); v_content text := btrim(p_content);
begin
  if v_user is null then return query select 'UNAUTHENTICATED', null::uuid; return; end if;
  if p_category is null or p_category not in ('MATERIAL_ANALYSIS','QUIZ_STUDY','PAYMENT_QUOTA','ACCOUNT_PROFILE','FRIEND_NOTIFICATION','BUG_REPORT','SUGGESTION_OTHER') then return query select 'INVALID_CATEGORY', null::uuid; return; end if;
  if v_title is null or char_length(v_title) not between 5 and 80 then return query select 'INVALID_TITLE', null::uuid; return; end if;
  if v_content is null or char_length(v_content) not between 10 and 2000 then return query select 'INVALID_CONTENT', null::uuid; return; end if;
  if coalesce(char_length(p_app_version),0)>32 or coalesce(char_length(p_build_number),0)>32 or coalesce(char_length(p_platform),0)>32 or coalesce(char_length(p_os_version),0)>128 or coalesce(char_length(p_locale),0)>32 or coalesce(char_length(p_current_route),0)>256 then return query select 'INVALID_CONTENT', null::uuid; return; end if;
  -- auth.uid() is the only verified production identity contract.
  -- Material linking remains fail-closed until its production contract is inspected.
  if p_related_material_id is not null then return query select 'INVALID_RELATED_MATERIAL', null::uuid; return; end if;
  if exists (select 1 from public.support_inquiries where user_id=v_user and created_at > now()-interval '60 seconds') then return query select 'RATE_LIMITED', null::uuid; return; end if;
  if (select count(*) from public.support_inquiries where user_id=v_user and created_at >= date_trunc('day',now())) >= 5 then return query select 'DAILY_LIMIT_EXCEEDED', null::uuid; return; end if;
  if exists (select 1 from public.support_inquiries where user_id=v_user and category=p_category and title=v_title and content=v_content and created_at > now()-interval '24 hours') then return query select 'DUPLICATE_INQUIRY', null::uuid; return; end if;
  insert into public.support_inquiries(user_id,category,title,content,app_version,build_number,platform,os_version,locale,current_route,related_material_id)
  values(v_user,p_category,v_title,v_content,nullif(left(p_app_version,32),''),nullif(left(p_build_number,32),''),nullif(left(p_platform,32),''),nullif(left(p_os_version,128),''),nullif(left(p_locale,32),''),nullif(left(p_current_route,256),''),p_related_material_id) returning id into v_id;
  return query select 'SUCCESS', v_id;
exception when others then
  return query select 'INTERNAL_ERROR', null::uuid;
end $$;

-- Server/Dashboard-only atomic reply operation. No authenticated grant.
create or replace function public.answer_support_inquiry(p_inquiry_id uuid, p_content text, p_responder_id uuid default null)
returns void language plpgsql security definer set search_path = pg_catalog, public, pg_temp as $$
begin
  if char_length(btrim(p_content)) not between 1 and 4000 then raise exception using errcode='22023', message='invalid_reply'; end if;
  perform 1 from public.support_inquiries where id=p_inquiry_id for update;
  if not found then raise exception using errcode='P0002', message='inquiry_not_found'; end if;
  insert into public.support_replies(inquiry_id,responder_id,content) values(p_inquiry_id,p_responder_id,btrim(p_content))
  on conflict(inquiry_id) do update set responder_id=excluded.responder_id, content=excluded.content, updated_at=now();
  update public.support_inquiries set status='ANSWERED', answered_at=coalesce(answered_at,now()), closed_at=null where id=p_inquiry_id;
  -- Notification insert intentionally belongs in a follow-up migration after the
  -- current mock notification feature receives an approved persistent schema.
end $$;

revoke all on function public.create_support_inquiry(text,text,text,text,text,text,text,text,text,uuid) from public;
grant execute on function public.create_support_inquiry(text,text,text,text,text,text,text,text,text,uuid) to authenticated;
revoke all on function public.answer_support_inquiry(uuid,text,uuid) from public;
grant execute on function public.answer_support_inquiry(uuid,text,uuid) to service_role;

comment on function public.answer_support_inquiry(uuid,text,uuid) is 'Dashboard/server only. Transactionally upserts one reply and marks inquiry ANSWERED.';
-- Recovery: revoke execute first; preserve tables/data; remove only these policies/functions/triggers after dependency review.