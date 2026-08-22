-- Applied only after every store resolved through currency_id. Irreversible.
alter table public.stores alter column currency_id set not null;
alter table public.stores drop column if exists currency;
