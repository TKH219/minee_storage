create table if not exists public.transaction_lines (
  id                    uuid          primary key default gen_random_uuid(),
  transaction_id        uuid          not null references public.transactions(id) on delete cascade,
  product_id            uuid          not null references public.products(id),
  batch_id              uuid          not null references public.batches(id),
  product_name_snapshot text          not null,
  unit_snapshot         text          not null,
  quantity_delta        numeric(14,3) not null,
  unit_price            numeric(18,2) not null default 0,
  unit_cost_snapshot    numeric(18,2) not null default 0,
  line_gross            numeric(18,2) not null default 0,
  line_cost             numeric(18,2) not null default 0,
  sort_order            int           not null default 0,
  created_at            timestamptz   not null default now(),
  updated_at            timestamptz   not null default now(),
  deleted_at            timestamptz
);

alter table public.transaction_lines drop constraint if exists transaction_lines_delta_nonzero;
alter table public.transaction_lines add constraint transaction_lines_delta_nonzero
  check (quantity_delta <> 0);

alter table public.transaction_lines drop constraint if exists transaction_lines_prices_sane;
alter table public.transaction_lines add constraint transaction_lines_prices_sane
  check (unit_price >= 0 and unit_cost_snapshot >= 0);

create index if not exists transaction_lines_transaction_idx on public.transaction_lines (transaction_id);
create index if not exists transaction_lines_product_idx     on public.transaction_lines (product_id);
create index if not exists transaction_lines_batch_idx       on public.transaction_lines (batch_id);

-- A line joins a transaction to a batch. The batch must sit in the same store
-- and hold the same product, or one shop's movement would deduct another's.
create or replace function public.transaction_lines_parents_agree()
returns trigger
language plpgsql
as $$
declare txn_store uuid; batch_store uuid; batch_product uuid;
begin
  select store_id into txn_store from public.transactions where id = new.transaction_id;
  select store_id, product_id into batch_store, batch_product
    from public.batches where id = new.batch_id;

  if txn_store is null then
    raise exception 'transaction % does not exist', new.transaction_id using errcode = 'P0002';
  end if;
  if batch_store is null then
    raise exception 'batch % does not exist', new.batch_id using errcode = 'P0002';
  end if;
  if txn_store <> batch_store then
    raise exception 'batch % belongs to a different store', new.batch_id using errcode = 'P0001';
  end if;
  if batch_product <> new.product_id then
    raise exception 'batch % holds a different product', new.batch_id using errcode = 'P0001';
  end if;
  return new;
end;
$$;

drop trigger if exists transaction_lines_parents_agree on public.transaction_lines;
create trigger transaction_lines_parents_agree
  before insert or update of transaction_id, product_id, batch_id on public.transaction_lines
  for each row execute function public.transaction_lines_parents_agree();

-- Allocation resolves against present stock and knows nothing about the header
-- date, so without this floor the ledger would show goods leaving before they
-- arrived.
create or replace function public.transaction_lines_after_arrival()
returns trigger
language plpgsql
as $$
declare occurred timestamptz; arrived timestamptz;
begin
  select occurred_at into occurred from public.transactions where id = new.transaction_id;
  select received_at into arrived  from public.batches      where id = new.batch_id;
  if occurred < arrived then
    raise exception 'transaction occurred at % but batch % arrived at %',
      occurred, new.batch_id, arrived using errcode = 'P0005';
  end if;
  return new;
end;
$$;

drop trigger if exists transaction_lines_after_arrival on public.transaction_lines;
create trigger transaction_lines_after_arrival
  after insert or update of transaction_id, batch_id on public.transaction_lines
  for each row execute function public.transaction_lines_after_arrival();

drop trigger if exists transaction_lines_touch_updated_at on public.transaction_lines;
create trigger transaction_lines_touch_updated_at
  before update on public.transaction_lines
  for each row execute function public.touch_updated_at();

alter table public.transaction_lines enable row level security;

drop policy if exists transaction_lines_select_own on public.transaction_lines;
create policy transaction_lines_select_own on public.transaction_lines
  for select to authenticated using (
    exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid())
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = auth.uid())
    and exists (select 1 from public.batches b
                  join public.stores s on s.id = b.store_id
                 where b.id = batch_id and s.owner_id = auth.uid())
  );

drop policy if exists transaction_lines_insert_own on public.transaction_lines;
create policy transaction_lines_insert_own on public.transaction_lines
  for insert to authenticated with check (
    exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid())
    and exists (select 1 from public.products p where p.id = product_id and p.user_id = auth.uid())
    and exists (select 1 from public.batches b
                  join public.stores s on s.id = b.store_id
                 where b.id = batch_id and s.owner_id = auth.uid())
  );

drop policy if exists transaction_lines_update_own on public.transaction_lines;
create policy transaction_lines_update_own on public.transaction_lines
  for update to authenticated
  using (exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid()))
  with check (exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid()));

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000200', 'transaction_lines')
on conflict (version) do nothing;
