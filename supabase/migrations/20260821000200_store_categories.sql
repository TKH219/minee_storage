create table if not exists public.store_categories (
  code       text primary key,
  name_vi    text not null,
  name_en    text not null,
  icon       text not null,
  sort_order int  not null
);

alter table public.store_categories enable row level security;

drop policy if exists store_categories_select on public.store_categories;
create policy store_categories_select on public.store_categories
  for select to authenticated
  using (true);

insert into public.store_categories (code, name_vi, name_en, icon, sort_order) values
  ('grocery',     'Tạp hóa',               'Grocery & convenience', 'basket',      10),
  ('mini_mart',   'Siêu thị mini',         'Mini supermarket',      'storefront',  20),
  ('restaurant',  'Nhà hàng',              'Restaurant',            'restaurant',  30),
  ('cafe',        'Quán cà phê',           'Cafe & drinks',         'cafe',        40),
  ('food_court',  'Khu ẩm thực',           'Food court',            'food_court',  50),
  ('warehouse',   'Kho hàng',              'Warehouse & storage',   'warehouse',   60),
  ('fashion',     'Thời trang',            'Fashion & apparel',     'apparel',     70),
  ('cosmetics',   'Mỹ phẩm',               'Cosmetics & beauty',    'cosmetics',   80),
  ('pharmacy',    'Nhà thuốc',             'Pharmacy',              'pharmacy',    90),
  ('electronics', 'Điện tử',               'Electronics',           'electronics', 100),
  ('stationery',  'Sách & văn phòng phẩm', 'Books & stationery',    'stationery',  110),
  ('online',      'Bán online',            'Online-only shop',      'online',      120),
  ('other',       'Khác',                  'Other',                 'other',       130)
on conflict (code) do nothing;
