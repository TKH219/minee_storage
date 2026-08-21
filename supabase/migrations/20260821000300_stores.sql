create table if not exists public.stores (
  id            uuid primary key default gen_random_uuid(),
  owner_id      uuid        not null references auth.users(id) on delete cascade,
  name          text        not null,
  category_code text        references public.store_categories(code),
  address       text,
  url           text,
  currency      text        not null default 'VND',
  phone         text,
  timezone      text        not null default 'Asia/Ho_Chi_Minh',
  logo_url      text,
  is_archived   boolean     not null default false,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create index if not exists stores_owner_id_idx on public.stores (owner_id);

alter table public.stores enable row level security;

drop policy if exists stores_select_own on public.stores;
create policy stores_select_own on public.stores
  for select to authenticated using (auth.uid() = owner_id);

drop policy if exists stores_insert_own on public.stores;
create policy stores_insert_own on public.stores
  for insert to authenticated with check (auth.uid() = owner_id);

drop policy if exists stores_update_own on public.stores;
create policy stores_update_own on public.stores
  for update to authenticated
  using (auth.uid() = owner_id) with check (auth.uid() = owner_id);

drop policy if exists stores_delete_own on public.stores;
create policy stores_delete_own on public.stores
  for delete to authenticated using (auth.uid() = owner_id);
