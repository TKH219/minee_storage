-- currencies gets a generated surrogate key; `code` stays as the natural key.
alter table public.currencies add column if not exists id uuid not null default gen_random_uuid();

alter table public.stores drop constraint if exists stores_currency_fkey;

do $$
begin
  if exists (select 1 from pg_constraint where conname = 'currencies_pkey') then
    alter table public.currencies drop constraint currencies_pkey;
  end if;
end $$;

alter table public.currencies drop constraint if exists currencies_code_key;
alter table public.currencies add constraint currencies_code_key unique (code);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'currencies_pkey') then
    alter table public.currencies add constraint currencies_pkey primary key (id);
  end if;
end $$;

alter table public.stores add column if not exists currency_id uuid;

update public.stores s
set currency_id = c.id
from public.currencies c
where c.code = s.currency
  and s.currency_id is null;

alter table public.stores drop constraint if exists stores_currency_id_fkey;
alter table public.stores
  add constraint stores_currency_id_fkey
  foreign key (currency_id) references public.currencies(id);
