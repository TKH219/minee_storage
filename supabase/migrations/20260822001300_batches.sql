create table if not exists public.batches (
  id                 uuid primary key default gen_random_uuid(),
  product_id         uuid           not null references public.products(id) on delete cascade,
  store_id           uuid           not null references public.stores(id)   on delete cascade,
  batch_code         text           not null,
  quantity_received  numeric(14,3)  not null,
  quantity_remaining numeric(14,3)  not null,
  unit_cost          numeric(18,2)  not null,
  expiry_date        date,
  received_at        timestamptz    not null default now(),
  supplier           text,
  storage_location   text,
  note               text,
  created_at         timestamptz    not null default now(),
  updated_at         timestamptz    not null default now(),
  deleted_at         timestamptz
);

alter table public.batches drop constraint if exists batches_quantities_sane;
alter table public.batches add constraint batches_quantities_sane
  check (quantity_received > 0
     and quantity_remaining >= 0
     and quantity_remaining <= quantity_received);

alter table public.batches drop constraint if exists batches_unit_cost_sane;
alter table public.batches add constraint batches_unit_cost_sane
  check (unit_cost >= 0);

create unique index if not exists batches_product_code_key
  on public.batches (product_id, batch_code);

create index if not exists batches_product_expiry_idx
  on public.batches (product_id, expiry_date);

create index if not exists batches_store_stocked_idx
  on public.batches (store_id) where quantity_remaining > 0 and deleted_at is null;

-- A batch joins a product to a store. Both must belong to the caller, or the
-- row would let one user's stock hang off another user's shop.
create or replace function public.batches_parents_agree()
returns trigger
language plpgsql
as $$
declare product_owner uuid; store_owner uuid;
begin
  select user_id  into product_owner from public.products where id = new.product_id;
  select owner_id into store_owner   from public.stores   where id = new.store_id;

  if product_owner is null then
    raise exception 'product % does not exist', new.product_id using errcode = 'P0002';
  end if;
  if store_owner is null then
    raise exception 'store % does not exist', new.store_id using errcode = 'P0002';
  end if;
  if product_owner <> store_owner then
    raise exception 'product owner and store owner differ' using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists batches_parents_agree on public.batches;
create trigger batches_parents_agree
  before insert or update of product_id, store_id on public.batches
  for each row execute function public.batches_parents_agree();

-- Sequential per product across every store, per the business doc. Store A may
-- therefore show gaps where the user's other stores hold the missing codes.
create or replace function public.batches_assign_code()
returns trigger
language plpgsql
as $$
declare next_number integer;
begin
  if new.batch_code is not null and length(btrim(new.batch_code)) > 0 then
    return new;
  end if;
  select coalesce(max(substring(batch_code from '\d+')::integer), 0) + 1
    into next_number
    from public.batches
   where product_id = new.product_id;
  new.batch_code = '#B-' || lpad(next_number::text, 4, '0');
  return new;
end;
$$;

drop trigger if exists batches_assign_code on public.batches;
create trigger batches_assign_code
  before insert on public.batches
  for each row execute function public.batches_assign_code();

drop trigger if exists batches_touch_updated_at on public.batches;
create trigger batches_touch_updated_at
  before update on public.batches
  for each row execute function public.touch_updated_at();

alter table public.batches enable row level security;

drop policy if exists batches_select_own on public.batches;
create policy batches_select_own on public.batches
  for select to authenticated using (
    exists (select 1 from public.products p where p.id = product_id and p.user_id  = auth.uid())
    and
    exists (select 1 from public.stores   s where s.id = store_id   and s.owner_id = auth.uid())
  );

drop policy if exists batches_insert_own on public.batches;
create policy batches_insert_own on public.batches
  for insert to authenticated with check (
    exists (select 1 from public.products p where p.id = product_id and p.user_id  = auth.uid())
    and
    exists (select 1 from public.stores   s where s.id = store_id   and s.owner_id = auth.uid())
  );

drop policy if exists batches_update_own on public.batches;
create policy batches_update_own on public.batches
  for update to authenticated
  using (
    exists (select 1 from public.products p where p.id = product_id and p.user_id  = auth.uid())
    and
    exists (select 1 from public.stores   s where s.id = store_id   and s.owner_id = auth.uid())
  )
  with check (
    exists (select 1 from public.products p where p.id = product_id and p.user_id  = auth.uid())
    and
    exists (select 1 from public.stores   s where s.id = store_id   and s.owner_id = auth.uid())
  );

drop policy if exists batches_delete_own on public.batches;
create policy batches_delete_own on public.batches
  for delete to authenticated using (
    exists (select 1 from public.products p where p.id = product_id and p.user_id  = auth.uid())
    and
    exists (select 1 from public.stores   s where s.id = store_id   and s.owner_id = auth.uid())
  );

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260822001300', 'batches')
on conflict (version) do nothing;
