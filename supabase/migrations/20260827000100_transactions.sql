create table if not exists public.transactions (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid          not null references auth.users(id) on delete cascade,
  store_id           uuid          not null references public.stores(id) on delete cascade,
  type               text          not null,
  code               text          not null,
  occurred_at        timestamptz   not null default now(),
  counterparty       text,
  counterparty_phone text,
  note               text,
  payment_method     text,
  reason             text,
  reason_note        text,
  items_subtotal     numeric(18,2) not null default 0,
  discount_total     numeric(18,2) not null default 0,
  buyer_charge_total numeric(18,2) not null default 0,
  seller_cost_total  numeric(18,2) not null default 0,
  pass_through_total numeric(18,2) not null default 0,
  buyer_total        numeric(18,2) not null default 0,
  net_revenue        numeric(18,2) not null default 0,
  cogs               numeric(18,2) not null default 0,
  gross_profit       numeric(18,2) not null default 0,
  net_profit         numeric(18,2) not null default 0,
  net_margin         numeric(9,6)  not null default 0,
  created_at         timestamptz   not null default now(),
  updated_at         timestamptz   not null default now(),
  deleted_at         timestamptz,
  amended_at         timestamptz,
  revision           int           not null default 0
);

alter table public.transactions drop constraint if exists transactions_type_known;
alter table public.transactions add constraint transactions_type_known
  check (type in ('sale','receive','write_off','adjust'));

alter table public.transactions drop constraint if exists transactions_payment_method_known;
alter table public.transactions add constraint transactions_payment_method_known
  check (payment_method is null
      or payment_method in ('cash','bank_transfer','card','ewallet','other'));

alter table public.transactions drop constraint if exists transactions_payment_method_shape;
alter table public.transactions add constraint transactions_payment_method_shape
  check ((type in ('write_off','adjust')) = (payment_method is null));

alter table public.transactions drop constraint if exists transactions_reason_known;
alter table public.transactions add constraint transactions_reason_known
  check (reason is null
      or reason in ('expired','damaged','lost','internal_use','other'));

alter table public.transactions drop constraint if exists transactions_reason_shape;
alter table public.transactions add constraint transactions_reason_shape
  check ((type = 'write_off') = (reason is not null));

-- Unbounded below on purpose: a sale whose cost exceeds its net revenue has a
-- margin under -100%, and numeric(9,6) holds it.
alter table public.transactions drop constraint if exists transactions_margin_sane;
alter table public.transactions add constraint transactions_margin_sane
  check (net_margin <= 1);

create unique index if not exists transactions_store_code_key
  on public.transactions (store_id, code) where deleted_at is null;

create index if not exists transactions_store_occurred_idx
  on public.transactions (store_id, occurred_at);
create index if not exists transactions_store_type_occurred_idx
  on public.transactions (store_id, type, occurred_at);
create index if not exists transactions_store_payment_occurred_idx
  on public.transactions (store_id, payment_method, occurred_at);

-- A code is never released, including by delete, so the highest ever issued is
-- read rather than the count of live rows.
create or replace function public.next_transaction_code(
  p_store_id uuid, p_type text, p_occurred_at timestamptz
) returns text
language plpgsql
as $$
declare
  prefix text;
  period text;
  next_number integer;
begin
  prefix := case p_type
    when 'sale'      then 'S'
    when 'receive'   then 'R'
    when 'write_off' then 'W'
    when 'adjust'    then 'A'
  end;
  if prefix is null then
    raise exception 'unknown transaction type %', p_type using errcode = '22023';
  end if;

  period := to_char(p_occurred_at, 'YYYYMM');

  select coalesce(max(substring(code from '(\d+)$')::integer), 0) + 1
    into next_number
    from public.transactions
   where store_id = p_store_id
     and type = p_type
     and code like prefix || '-' || period || '-%';

  return prefix || '-' || period || '-' || lpad(next_number::text, 4, '0');
end;
$$;

drop trigger if exists transactions_touch_updated_at on public.transactions;
create trigger transactions_touch_updated_at
  before update on public.transactions
  for each row execute function public.touch_updated_at();

alter table public.transactions enable row level security;

drop policy if exists transactions_select_own on public.transactions;
create policy transactions_select_own on public.transactions
  for select to authenticated using (
    user_id = auth.uid()
    and exists (select 1 from public.stores s where s.id = store_id and s.owner_id = auth.uid())
  );

drop policy if exists transactions_insert_own on public.transactions;
create policy transactions_insert_own on public.transactions
  for insert to authenticated with check (
    user_id = auth.uid()
    and exists (select 1 from public.stores s where s.id = store_id and s.owner_id = auth.uid())
  );

drop policy if exists transactions_update_own on public.transactions;
create policy transactions_update_own on public.transactions
  for update to authenticated
  using (
    user_id = auth.uid()
    and exists (select 1 from public.stores s where s.id = store_id and s.owner_id = auth.uid())
  )
  with check (
    user_id = auth.uid()
    and exists (select 1 from public.stores s where s.id = store_id and s.owner_id = auth.uid())
  );

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000100', 'transactions')
on conflict (version) do nothing;
