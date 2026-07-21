-- Mameroom profiles v1 read-only preflight.
-- Run this in Supabase SQL Editor before applying the profiles foundation
-- migration. This script does not modify auth or public data.

with auth_profile_source as (
  select
    u.id,
    nullif(
      regexp_replace(
        btrim(coalesce(u.raw_user_meta_data ->> 'nickname', '')),
        '\s+',
        ' ',
        'g'
      ),
      ''
    ) as nickname
  from auth.users u
)
select
  count(*) as auth_user_count,
  count(*) filter (where nickname is null) as missing_nickname_count,
  count(*) filter (
    where nickname is not null
      and char_length(nickname) not between 2 and 30
  ) as invalid_nickname_count
from auth_profile_source;

with auth_profile_source as (
  select
    u.id,
    u.created_at,
    nullif(
      regexp_replace(
        btrim(coalesce(u.raw_user_meta_data ->> 'nickname', '')),
        '\s+',
        ' ',
        'g'
      ),
      ''
    ) as nickname
  from auth.users u
)
select
  id,
  created_at,
  case
    when nickname is null then 'missing'
    when char_length(nickname) not between 2 and 30 then 'invalid_length'
    else 'valid'
  end as nickname_state
from auth_profile_source
where nickname is null
   or char_length(nickname) not between 2 and 30
order by created_at, id;

with normalized_nicknames as (
  select
    u.id,
    lower(
      regexp_replace(
        btrim(coalesce(u.raw_user_meta_data ->> 'nickname', '')),
        '\s+',
        ' ',
        'g'
      )
    ) as normalized_nickname
  from auth.users u
)
select
  normalized_nickname,
  count(*) as duplicate_count
from normalized_nicknames
where normalized_nickname <> ''
group by normalized_nickname
having count(*) > 1
order by normalized_nickname;

select
  to_regclass('public.profiles') as profiles_relation,
  to_regprocedure('public.handle_new_auth_user_profile()')
    as signup_trigger_function,
  to_regprocedure('public.set_profiles_updated_at()')
    as updated_at_trigger_function;
