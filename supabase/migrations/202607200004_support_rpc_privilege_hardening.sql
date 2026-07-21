-- Explicit remote-role hardening discovered by postflight ACL audit.
revoke all on function public.create_support_inquiry(
  text, text, text, text, text, text, text, text, text, uuid
) from public;
revoke execute on function public.create_support_inquiry(
  text, text, text, text, text, text, text, text, text, uuid
) from anon;
grant execute on function public.create_support_inquiry(
  text, text, text, text, text, text, text, text, text, uuid
) to authenticated;

revoke all on function public.answer_support_inquiry(uuid, text, uuid)
  from public;
revoke execute on function public.answer_support_inquiry(uuid, text, uuid)
  from anon;
revoke execute on function public.answer_support_inquiry(uuid, text, uuid)
  from authenticated;
grant execute on function public.answer_support_inquiry(uuid, text, uuid)
  to service_role;