create table if not exists public.transaction_fees (
  id              uuid          primary key default gen_random_uuid(),
  transaction_id  uuid          not null references public.transactions(id) on delete cascade,
  name            text          not null,
  direction       text          not null,
  kind            text          not null,
  value           numeric(18,4) not null,
  is_pass_through boolean       not null default false,
  computed_amount numeric(18,2) not null default 0,
  sort_order      int           not null default 0,
  created_at      timestamptz   not null default now(),
  updated_at      timestamptz   not null default now(),
  deleted_at      timestamptz
);

alter table public.transaction_fees drop constraint if exists transaction_fees_direction_known;
alter table public.transaction_fees add constraint transaction_fees_direction_known
  check (direction in ('buyer_charge','seller_cost','discount'));

alter table public.transaction_fees drop constraint if exists transaction_fees_kind_known;
alter table public.transaction_fees add constraint transaction_fees_kind_known
  check (kind in ('fixed','percent'));

alter table public.transaction_fees drop constraint if exists transaction_fees_value_sane;
alter table public.transaction_fees add constraint transaction_fees_value_sane
  check (value >= 0);

create index if not exists transaction_fees_transaction_idx
  on public.transaction_fees (transaction_id);

-- A write_off or adjust carries no money, so it carries no fee; and a receive
-- has no seller side, so seller_cost is meaningless on one.
create or replace function public.transaction_fees_allowed()
returns trigger
language plpgsql
as $$
declare txn_type text;
begin
  select type into txn_type from public.transactions where id = new.transaction_id;
  if txn_type is null then
    raise exception 'transaction % does not exist', new.transaction_id using errcode = 'P0002';
  end if;
  if txn_type in ('write_off','adjust') then
    raise exception 'a % carries no fees', txn_type using errcode = 'P0006';
  end if;
  if txn_type = 'receive' and new.direction = 'seller_cost' then
    raise exception 'a receive has no seller side' using errcode = 'P0006';
  end if;
  return new;
end;
$$;

drop trigger if exists transaction_fees_allowed on public.transaction_fees;
create trigger transaction_fees_allowed
  before insert or update of transaction_id, direction on public.transaction_fees
  for each row execute function public.transaction_fees_allowed();

drop trigger if exists transaction_fees_touch_updated_at on public.transaction_fees;
create trigger transaction_fees_touch_updated_at
  before update on public.transaction_fees
  for each row execute function public.touch_updated_at();

alter table public.transaction_fees enable row level security;

drop policy if exists transaction_fees_select_own on public.transaction_fees;
create policy transaction_fees_select_own on public.transaction_fees
  for select to authenticated using (
    exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid())
  );

drop policy if exists transaction_fees_insert_own on public.transaction_fees;
create policy transaction_fees_insert_own on public.transaction_fees
  for insert to authenticated with check (
    exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid())
  );

drop policy if exists transaction_fees_update_own on public.transaction_fees;
create policy transaction_fees_update_own on public.transaction_fees
  for update to authenticated
  using (exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid()))
  with check (exists (select 1 from public.transactions t where t.id = transaction_id and t.user_id = auth.uid()));

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000300', 'transaction_fees')
on conflict (version) do nothing;
