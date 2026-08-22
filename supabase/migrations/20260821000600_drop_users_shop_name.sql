-- Applied only after the backfill in 20260821000400 was verified to have left
-- no user with a shop name and no store. Irreversible.
alter table public.users drop column if exists shop_name;
