-- Friend Room read-only RPC. Additive; does not widen table RLS.
create or replace function public.get_friend_room(p_friend_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = pg_catalog, public, pg_temp
as $$
declare
  v_user uuid := auth.uid();
  v_profile public.profiles%rowtype;
  v_layouts jsonb;
begin
  if v_user is null then
    raise exception using errcode='42501', message='friend_room_authentication_required';
  end if;
  if p_friend_id is null or p_friend_id = v_user then
    raise exception using errcode='22023', message='friend_room_invalid_target';
  end if;
  select * into v_profile from public.profiles
  where id=p_friend_id and account_status='active';
  if not found then
    raise exception using errcode='P0002', message='friend_room_unavailable';
  end if;
  if exists(select 1 from public.user_blocks b where
    (b.blocker_id=v_user and b.blocked_id=p_friend_id) or
    (b.blocker_id=p_friend_id and b.blocked_id=v_user)) then
    raise exception using errcode='42501', message='friend_room_access_denied';
  end if;
  if not exists(select 1 from public.friendships f where
    f.user_low_id=least(v_user,p_friend_id) and
    f.user_high_id=greatest(v_user,p_friend_id)) then
    raise exception using errcode='42501', message='friend_room_not_friend';
  end if;
  if v_profile.room_visibility <> 'friends' then
    raise exception using errcode='42501', message='friend_room_private';
  end if;
  select coalesce(jsonb_agg(jsonb_build_object(
    'layout_id',l.id,'position_x',l.position_x,'position_y',l.position_y,
    'item_id',ri.id,'item_code',ri.item_code,'name',ri.name,
    'description',ri.description,'item_type',ri.item_type,
    'rarity',ri.rarity,'asset_key',ri.asset_key,'asset_path',ri.asset_path,
    'default_position_x',ri.default_position_x,
    'default_position_y',ri.default_position_y
  ) order by l.created_at,l.id),'[]'::jsonb) into v_layouts
  from public.user_room_layouts l
  join public.room_items ri on ri.id=l.item_id and ri.is_active
  where l.user_id=p_friend_id
    and exists(select 1 from public.user_items ui
      where ui.user_id=p_friend_id and ui.item_id=l.item_id);
  return jsonb_build_object(
    'friend_id',v_profile.id,'nickname',v_profile.nickname,
    'avatar_key',v_profile.avatar_key,'level',v_profile.level,
    'status_message',v_profile.status_message,
    'visit_state','loaded','is_decorated',jsonb_array_length(v_layouts)>0,
    'furniture',v_layouts
  );
end
$$;
revoke all on function public.get_friend_room(uuid) from public;
revoke execute on function public.get_friend_room(uuid) from anon;
grant execute on function public.get_friend_room(uuid) to authenticated;
comment on function public.get_friend_room(uuid) is
  'Read-only Friend Room projection. Requires active friendship, no block, and friends visibility.';