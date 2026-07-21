-- All destructive checks are rolled back.
select set_config('request.jwt.claim.sub','a1cdbcbc-b682-4eef-9c1a-48498481fd4e',false);
do $$
begin
  begin
    perform public.get_friend_room('19cc19c9-0248-45bc-9f53-1a362b9ec77d'::uuid);
    raise exception 'nonfriend_access_was_not_blocked';
  exception when sqlstate '42501' then null;
  end;
end $$;
select 'nonfriend_blocked' as result;

begin;
delete from public.friendships
where user_low_id=least('1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e'::uuid,'a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid)
  and user_high_id=greatest('1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e'::uuid,'a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid);
select set_config('request.jwt.claim.sub','1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e',true);
do $$
begin
  begin
    perform public.get_friend_room('a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid);
    raise exception 'deleted_friend_access_was_not_blocked';
  exception when sqlstate '42501' then null;
  end;
end $$;
rollback;
select 'deleted_friend_blocked_and_rolled_back' as result,
       count(*) as friendship_preserved
from public.friendships
where user_low_id=least('1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e'::uuid,'a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid)
  and user_high_id=greatest('1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e'::uuid,'a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid);

begin;
update public.profiles set room_visibility='private' where id='a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid;
select set_config('request.jwt.claim.sub','1e7c995b-6eee-4eff-8ec2-5b0e07ecbe4e',true);
do $$
begin
  begin
    perform public.get_friend_room('a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid);
    raise exception 'private_room_access_was_not_blocked';
  exception when sqlstate '42501' then null;
  end;
end $$;
rollback;
select 'private_room_blocked_and_rolled_back' as result, room_visibility
from public.profiles where id='a1cdbcbc-b682-4eef-9c1a-48498481fd4e'::uuid;