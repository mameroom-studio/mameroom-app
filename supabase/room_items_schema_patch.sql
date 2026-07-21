-- Room Items schema patch for Home Room + Shop MVP.
-- Safe to run multiple times in Supabase SQL Editor.
-- Fixes client/schema mismatch where ShopPage expects description, rarity,
-- asset_key, default_position_x, and default_position_y.

alter table public.room_items
  add column if not exists description text,
  add column if not exists rarity text,
  add column if not exists asset_key text,
  add column if not exists default_position_x double precision,
  add column if not exists default_position_y double precision;

update public.room_items
set description = coalesce(description, '');

update public.room_items
set rarity = coalesce(nullif(rarity, ''), 'common');

update public.room_items
set asset_key = coalesce(nullif(asset_key, ''), nullif(item_code, ''), id::text);

update public.room_items
set default_position_x = coalesce(default_position_x, 0.5),
    default_position_y = coalesce(default_position_y, 0.7);

alter table public.room_items
  alter column description set default '',
  alter column rarity set default 'common',
  alter column default_position_x set default 0.5,
  alter column default_position_y set default 0.7;

alter table public.room_items
  alter column description set not null,
  alter column rarity set not null,
  alter column asset_key set not null,
  alter column default_position_x set not null,
  alter column default_position_y set not null;

-- If item_type is backed by an enum, add the MVP item types before inserting seed data.
do $$
declare
  enum_type regtype;
begin
  select a.atttypid::regtype
    into enum_type
  from pg_attribute a
  join pg_class c on c.oid = a.attrelid
  join pg_namespace n on n.oid = c.relnamespace
  join pg_type t on t.oid = a.atttypid
  where n.nspname = 'public'
    and c.relname = 'room_items'
    and a.attname = 'item_type'
    and t.typtype = 'e'
  limit 1;

  if enum_type is not null then
    execute format('alter type %s add value if not exists %L', enum_type, 'rug');
    execute format('alter type %s add value if not exists %L', enum_type, 'clock');
  end if;
end $$;

alter table public.room_items
  drop constraint if exists room_items_item_type_check;

alter table public.room_items
  add constraint room_items_item_type_check
  check (item_type in ('chair', 'desk', 'plant', 'lamp', 'rug', 'clock')) not valid;

alter table public.room_items
  drop constraint if exists room_items_rarity_check;

alter table public.room_items
  add constraint room_items_rarity_check
  check (rarity in ('common', 'uncommon', 'rare')) not valid;

insert into public.room_items (
  item_code,
  name,
  description,
  price,
  rarity,
  item_type,
  asset_key,
  asset_path,
  default_position_x,
  default_position_y,
  is_active
)
values
  ('basic_chair', '기본 의자', '작은 공부 의자', 100, 'common', 'chair', 'basic_chair', 'assets/room/basic_chair.png', 0.34, 0.72, true),
  ('basic_desk', '기본 책상', '책과 노트를 올려둘 책상', 150, 'common', 'desk', 'basic_desk', 'assets/room/basic_desk.png', 0.52, 0.66, true),
  ('small_plant', '작은 화분', '방 한쪽에 놓는 작은 화분', 120, 'common', 'plant', 'small_plant', 'assets/room/small_plant.png', 0.80, 0.62, true),
  ('basic_lamp', '기본 스탠드', '늦은 공부를 밝혀주는 스탠드', 180, 'common', 'lamp', 'basic_lamp', 'assets/room/basic_lamp.png', 0.20, 0.56, true),
  ('small_rug', '작은 러그', '기본 바닥 위에 놓는 포근한 러그', 200, 'common', 'rug', 'small_rug', 'assets/room/small_rug.png', 0.52, 0.84, true),
  ('wall_clock', '벽시계', '복습 시간을 알려주는 벽시계', 250, 'common', 'clock', 'wall_clock', 'assets/room/wall_clock.png', 0.78, 0.24, true)
on conflict (item_code) do update
set name = excluded.name,
    description = excluded.description,
    price = excluded.price,
    rarity = excluded.rarity,
    item_type = excluded.item_type,
    asset_key = excluded.asset_key,
    asset_path = excluded.asset_path,
    default_position_x = excluded.default_position_x,
    default_position_y = excluded.default_position_y,
    is_active = excluded.is_active;

-- Verification query:
-- select item_code, name, description, item_type, rarity, price, asset_key,
--        default_position_x, default_position_y, is_active
-- from public.room_items
-- order by price;
