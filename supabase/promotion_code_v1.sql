-- Mameroom Promotion Code System v1.
-- Additive. MVP payout: MCOIN through the existing wallet/coin ledger.
-- QUESTION remains an allowed master type but fails closed until a canonical
-- question entitlement ledger exists.
begin;
create extension if not exists pgcrypto with schema extensions;

do $$
begin
  if to_regclass('public.profiles') is null
    or to_regclass('public.user_wallets') is null
    or to_regclass('public.coin_transactions') is null then
    raise exception 'promotion_code_v1 preflight failed: prerequisite schema is missing';
  end if;
end $$;

create table if not exists public.promotion_codes (
  id uuid primary key default gen_random_uuid(),
  code text not null,
  title text not null,
  description text,
  code_type text not null check (code_type in ('PUBLIC','PRIVATE','ONE_TIME','LIMITED')),
  reward_type text not null check (reward_type in (
    'QUESTION','MCOIN','PREMIUM_DAYS','ITEM','BADGE','MEMORY_TREE'
  )),
  reward_value bigint not null,
  start_at timestamptz,
  end_at timestamptz,
  max_total_use integer check (max_total_use is null or max_total_use > 0),
  max_user_use integer not null default 1 check (max_user_use > 0),
  current_use_count integer not null default 0 check (current_use_count >= 0),
  enabled boolean not null default true,
  metadata jsonb not null default '{}'::jsonb,
  memo text,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  check (code = upper(btrim(code))),
  check (code ~ '^[A-Z0-9_-]{3,64}$'),
  check (start_at is null or end_at is null or start_at < end_at),
  check (max_total_use is null or current_use_count <= max_total_use)
);
create unique index if not exists promotion_codes_normalized_code_uq
  on public.promotion_codes(upper(btrim(code)));
create index if not exists promotion_codes_active_window_idx
  on public.promotion_codes(enabled,start_at,end_at);

create table if not exists public.promotion_redemptions (
  id uuid primary key default gen_random_uuid(),
  promotion_id uuid not null references public.promotion_codes(id),
  user_id uuid not null references auth.users(id) on delete cascade,
  use_number integer not null check (use_number > 0),
  reward_type text not null,
  reward_value bigint not null,
  reward_snapshot jsonb not null,
  used_at timestamptz not null default now(),
  client_version text,
  device_type text,
  created_at timestamptz not null default now(),
  unique(promotion_id,user_id,use_number)
);
create index if not exists promotion_redemptions_promotion_idx
  on public.promotion_redemptions(promotion_id,used_at desc);
create index if not exists promotion_redemptions_user_idx
  on public.promotion_redemptions(user_id,used_at desc);
create index if not exists promotion_redemptions_promotion_user_idx
  on public.promotion_redemptions(promotion_id,user_id);

create table if not exists public.promotion_attempts (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references auth.users(id) on delete set null,
  code_hash text,
  success boolean not null,
  result_code text not null,
  promotion_id uuid references public.promotion_codes(id) on delete set null,
  client_version text,
  device_type text,
  attempted_at timestamptz not null default now()
);
create index if not exists promotion_attempts_user_time_idx
  on public.promotion_attempts(user_id,attempted_at desc);
create index if not exists promotion_attempts_result_time_idx
  on public.promotion_attempts(result_code,attempted_at desc);

create table if not exists public.reward_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  source_type text not null,
  source_id uuid not null,
  reward_type text not null,
  reward_value bigint not null,
  balance_before bigint,
  balance_after bigint,
  reward_snapshot jsonb not null,
  idempotency_key text not null,
  created_at timestamptz not null default now(),
  unique(user_id,idempotency_key)
);
create index if not exists reward_transactions_user_created_idx
  on public.reward_transactions(user_id,created_at desc);

alter table public.coin_transactions drop constraint if exists coin_transactions_transaction_type_check;
alter table public.coin_transactions add constraint coin_transactions_transaction_type_check
  check (transaction_type in (
    'correct_answer','streak_bonus','review_complete','memory_increase',
    'first_study','today_goal_complete','achievement_reward','room_purchase',
    'streak_7_bonus','streak_30_bonus','streak_100_bonus','promotion_reward'
  )) not valid;
alter table public.coin_transactions drop constraint if exists coin_transactions_source_type_check;
alter table public.coin_transactions add constraint coin_transactions_source_type_check
  check (source_type in (
    'quiz','review','memory','study','goal','achievement','room_item','streak','promotion'
  )) not valid;

alter table public.promotion_codes enable row level security;
alter table public.promotion_redemptions enable row level security;
alter table public.promotion_attempts enable row level security;
alter table public.reward_transactions enable row level security;

revoke all on public.promotion_codes,public.promotion_redemptions,
  public.promotion_attempts,public.reward_transactions from anon,authenticated;
grant select on public.promotion_redemptions,public.reward_transactions to authenticated;
drop policy if exists "Users read own promotion redemptions" on public.promotion_redemptions;
drop policy if exists "Users read own promotion rewards" on public.reward_transactions;
create policy "Users read own promotion redemptions" on public.promotion_redemptions
  for select to authenticated using(user_id=auth.uid());
create policy "Users read own promotion rewards" on public.reward_transactions
  for select to authenticated using(user_id=auth.uid());

create or replace function public.redeem_promotion_code(
  p_code text,p_client_version text default null,p_device_type text default null
) returns jsonb language plpgsql security definer
set search_path=public,extensions,pg_temp as $$
declare
  v_user uuid:=auth.uid();
  v_code text:=upper(btrim(coalesce(p_code,'')));
  v_hash text;
  v_promo promotion_codes%rowtype;
  v_user_count integer;
  v_redemption uuid:=gen_random_uuid();
  v_before bigint;
  v_after bigint;
  v_result text;
  v_reward jsonb;
begin
  if char_length(v_code) not between 3 and 64 or v_code !~ '^[A-Z0-9_-]+$' then
    v_code:='';
  end if;
  v_hash:=case when v_code='' then null else encode(digest(v_code,'sha256'),'hex') end;
  if v_user is null then
    return jsonb_build_object('success',false,'result_code','UNAUTHENTICATED');
  end if;
  <<validation>>
  begin
  if not exists(select 1 from profiles where id=v_user and account_status='active') then
    v_result:='UNAUTHENTICATED'; exit validation;
  end if;
  if v_code='' then v_result:='INVALID_CODE'; exit validation; end if;

  select * into v_promo from promotion_codes where code=v_code for update;
  if not found then v_result:='INVALID_CODE'; exit validation; end if;
  if not v_promo.enabled then v_result:='DISABLED'; exit validation; end if;
  if v_promo.start_at is not null and now()<v_promo.start_at then
    v_result:='NOT_STARTED'; exit validation;
  end if;
  if v_promo.end_at is not null and now()>=v_promo.end_at then
    v_result:='EXPIRED'; exit validation;
  end if;
  if v_promo.max_total_use is not null
    and v_promo.current_use_count>=v_promo.max_total_use then
    v_result:='TOTAL_LIMIT_EXCEEDED'; exit validation;
  end if;
  select count(*) into v_user_count from promotion_redemptions
    where promotion_id=v_promo.id and user_id=v_user;
  if v_user_count>=v_promo.max_user_use then
    v_result:=case when v_promo.max_user_use=1 then 'ALREADY_USED'
      else 'USER_LIMIT_EXCEEDED' end;
    exit validation;
  end if;
  if v_promo.reward_type<>'MCOIN' then
    v_result:='UNSUPPORTED_REWARD'; exit validation;
  end if;
  if v_promo.reward_value<=0 or v_promo.reward_value>2147483647 then
    v_result:='INVALID_REWARD'; exit validation;
  end if;

  begin
    insert into user_wallets(user_id) values(v_user) on conflict(user_id) do nothing;
    select balance into v_before from user_wallets where user_id=v_user for update;
    update user_wallets set balance=balance+v_promo.reward_value::integer,
      total_earned=total_earned+v_promo.reward_value::integer,updated_at=now()
      where user_id=v_user returning balance into v_after;
    v_reward:=jsonb_build_object('type',v_promo.reward_type,'value',v_promo.reward_value);
    insert into promotion_redemptions(
      id,promotion_id,user_id,use_number,reward_type,reward_value,reward_snapshot,
      client_version,device_type
    ) values(
      v_redemption,v_promo.id,v_user,v_user_count+1,v_promo.reward_type,
      v_promo.reward_value,v_reward,left(p_client_version,64),left(p_device_type,32)
    );
    insert into coin_transactions(
      user_id,transaction_type,amount,reason,reference_id,idempotency_key,
      source_type,source_id
    ) values(
      v_user,'promotion_reward',v_promo.reward_value::integer,'promotion',
      v_redemption,'promotion:'||v_redemption,'promotion',v_redemption
    );
    insert into reward_transactions(
      user_id,source_type,source_id,reward_type,reward_value,balance_before,
      balance_after,reward_snapshot,idempotency_key
    ) values(
      v_user,'PROMOTION',v_redemption,v_promo.reward_type,v_promo.reward_value,
      v_before,v_after,v_reward,'promotion:'||v_redemption
    );
    update promotion_codes set current_use_count=current_use_count+1,updated_at=now()
      where id=v_promo.id;
    insert into promotion_attempts(
      user_id,code_hash,success,result_code,promotion_id,client_version,device_type
    ) values(v_user,v_hash,true,'SUCCESS',v_promo.id,
      left(p_client_version,64),left(p_device_type,32));
  exception when others then
    insert into promotion_attempts(
      user_id,code_hash,success,result_code,promotion_id,client_version,device_type
    ) values(v_user,v_hash,false,'REWARD_FAILED',v_promo.id,
      left(p_client_version,64),left(p_device_type,32));
    return jsonb_build_object('success',false,'result_code','REWARD_FAILED');
  end;
  return jsonb_build_object('success',true,'result_code','SUCCESS',
    'promotion_id',v_promo.id,'reward',v_reward);
  end validation;

  <<log_failure>>
  insert into promotion_attempts(
    user_id,code_hash,success,result_code,promotion_id,client_version,device_type
  ) values(v_user,v_hash,false,v_result,v_promo.id,
    left(p_client_version,64),left(p_device_type,32));
  return jsonb_build_object('success',false,'result_code',v_result);
exception when others then
  return jsonb_build_object('success',false,'result_code','INTERNAL_ERROR');
end $$;

revoke all on function public.redeem_promotion_code(text,text,text) from public,anon;
grant execute on function public.redeem_promotion_code(text,text,text) to authenticated;
comment on table public.promotion_codes is
  'Service-role managed promotion master. No client direct access.';
comment on table public.promotion_attempts is
  'Private audit log. Stores SHA-256 normalized-code hashes, never raw inputs.';
commit;

-- Manual rollback: revoke RPC first, preserve ledgers for audit, then drop
-- function/table objects only after confirming no production dependency.
