-- Explicitly remove Supabase's default anon EXECUTE grants.
-- RPCs also validate auth.uid(), but least privilege should block invocation
-- before function execution.

begin;

revoke execute on function public.get_my_edit_profile() from anon;
revoke execute on function public.update_my_profile(
  text, text, text, uuid, uuid, timestamptz
) from anon;
revoke execute on function public.search_friend_profiles(
  text, integer, uuid
) from anon;
revoke execute on function public.list_friend_profiles(text) from anon;
revoke execute on function public.send_friend_request(uuid, uuid) from anon;
revoke execute on function public.respond_friend_request(uuid, boolean)
  from anon;
revoke execute on function public.cancel_friend_request(uuid) from anon;
revoke execute on function public.remove_friend(uuid) from anon;
revoke execute on function public.set_user_block(uuid, boolean) from anon;

commit;
