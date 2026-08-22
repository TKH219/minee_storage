-- Every table carries the same three audit timestamps.
alter table public.users             add column if not exists deleted_at timestamptz;
alter table public.stores            add column if not exists deleted_at timestamptz;

alter table public.store_categories  add column if not exists created_at timestamptz not null default now();
alter table public.store_categories  add column if not exists updated_at timestamptz not null default now();
alter table public.store_categories  add column if not exists deleted_at timestamptz;

alter table public.currencies        add column if not exists created_at timestamptz not null default now();
alter table public.currencies        add column if not exists updated_at timestamptz not null default now();
alter table public.currencies        add column if not exists deleted_at timestamptz;

-- Soft delete now carries the meaning is_archived used to.
update public.stores set deleted_at = now()
where is_archived is true and deleted_at is null;

alter table public.stores drop column if exists is_archived;

create index if not exists stores_owner_live_idx
  on public.stores (owner_id) where deleted_at is null;
