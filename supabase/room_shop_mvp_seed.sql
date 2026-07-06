-- Home Room + Shop MVP seed/migration.
-- Safe to run multiple times. Does not delete existing user data.

alter table public.room_items
  add column if not exists description text not null default '',
  add column if not exists rarity text not null default 'common',
  add column if not exists asset_key text,
  add column if not exists default_position_x double precision not null default 0.5,
  add column if not exists default_position_y double precision not null default 0.7;

update public.room_items
set asset_key = item_code
where asset_key is null or asset_key = '';

alter table public.room_items
  alter column asset_key set not null;

alter table public.room_items
  drop constraint if exists room_items_item_type_check;

alter table public.room_items
  add constraint room_items_item_type_check
  check (item_type in ('chair', 'desk', 'plant', 'lamp', 'rug', 'clock'));

alter table public.room_items
  drop constraint if exists room_items_rarity_check;

alter table public.room_items
  add constraint room_items_rarity_check
  check (rarity in ('common', 'uncommon', 'rare'));

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
