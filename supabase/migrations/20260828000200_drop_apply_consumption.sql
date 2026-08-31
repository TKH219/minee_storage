-- The ledger is the only write path into a lot's remaining quantity. That was
-- true on the device the moment ProductRepository.consume went; this makes it
-- true at the server too, so no future caller can find a second door.
--
-- apply_consumption deducted stock with no reason, no money and no audit trail.
-- Every movement it used to serve is now a transaction: a sale, a write-off or
-- a stock count, each with its own row, its own code and its own reversal.
drop function if exists public.apply_consumption(uuid, uuid, jsonb);

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260828000200', 'drop_apply_consumption')
on conflict (version) do nothing;
