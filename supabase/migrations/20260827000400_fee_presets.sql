create table if not exists public.fee_presets (
  id              uuid          primary key default gen_random_uuid(),
  user_id         uuid          not null references auth.users(id) on delete cascade,
  store_id        uuid          not null references public.stores(id) on delete cascade,
  name            text          not null,
  direction       text          not null,
  kind            text          not null,
  value           numeric(18,4) not null,
  is_pass_through boolean       not null default false,
  is_default      boolean       not null default false,
  sort_order      int           not null default 0,
  created_at      timestamptz   not null default now(),
  updated_at      timestamptz   not null default now(),
  deleted_at      timestamptz
);

alter table public.fee_presets drop constraint if exists fee_presets_direction_known;
alter table public.fee_presets add constraint fee_presets_direction_known
  check (direction in ('buyer_charge','seller_cost','discount'));

alter table public.fee_presets drop constraint if exists fee_presets_kind_known;
alter table public.fee_presets add constraint fee_presets_kind_known
  check (kind in ('fixed','percent'));

alter table public.fee_presets drop constraint if exists fee_presets_value_sane;
alter table public.fee_presets add constraint fee_presets_value_sane
  check (value >= 0);

create index if not exists fee_presets_store_idx
  on public.fee_presets (store_id, sort_order) where deleted_at is null;

drop trigger if exists fee_presets_touch_updated_at on public.fee_presets;
create trigger fee_presets_touch_updated_at
  before update on public.fee_presets
  for each row execute function public.touch_updated_at();

alter table public.fee_presets enable row level security;

drop policy if exists fee_presets_select_own on public.fee_presets;
create policy fee_presets_select_own on public.fee_presets
  for select to authenticated using (
    user_id = auth.uid()
    and exists (select 1 from public.stores s where s.id = store_id and s.owner_id = auth.uid())
  );

drop policy if exists fee_presets_insert_own on public.fee_presets;
create policy fee_presets_insert_own on public.fee_presets
  for insert to authenticated with check (
    user_id = auth.uid()
    and exists (select 1 from public.stores s where s.id = store_id and s.owner_id = auth.uid())
  );

drop policy if exists fee_presets_update_own on public.fee_presets;
create policy fee_presets_update_own on public.fee_presets
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
  ('20260827000400', 'fee_presets')
on conflict (version) do nothing;
