create table if not exists public.products (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid        not null references auth.users(id) on delete cascade,
  name       text        not null,
  barcode    text,
  brand      text,
  category   text,
  unit       text        not null default 'piece',
  image_url  text,
  notes      text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  deleted_at timestamptz
);

alter table public.products drop constraint if exists products_unit_allowed;
alter table public.products add constraint products_unit_allowed
  check (unit in ('piece', 'kg', 'g', 'litre', 'ml', 'box', 'pack'));

alter table public.products drop constraint if exists products_name_not_blank;
alter table public.products add constraint products_name_not_blank
  check (length(btrim(name)) > 0);

-- Spans archived rows on purpose: an archived product keeps its barcode
-- reserved, so Restore can never collide with a product created meanwhile.
create unique index if not exists products_user_barcode_key
  on public.products (user_id, barcode) where barcode is not null;

create index if not exists products_user_live_idx
  on public.products (user_id) where deleted_at is null;

drop trigger if exists products_touch_updated_at on public.products;
create trigger products_touch_updated_at
  before update on public.products
  for each row execute function public.touch_updated_at();

alter table public.products enable row level security;

drop policy if exists products_select_own on public.products;
create policy products_select_own on public.products
  for select to authenticated using (auth.uid() = user_id);

drop policy if exists products_insert_own on public.products;
create policy products_insert_own on public.products
  for insert to authenticated with check (auth.uid() = user_id);

drop policy if exists products_update_own on public.products;
create policy products_update_own on public.products
  for update to authenticated
  using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists products_delete_own on public.products;
create policy products_delete_own on public.products
  for delete to authenticated using (auth.uid() = user_id);

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260822001200', 'products')
on conflict (version) do nothing;
