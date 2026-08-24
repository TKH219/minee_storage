insert into supabase_migrations.schema_migrations (version, name) values
  ('20260821000100', 'profile_columns'),
  ('20260821000200', 'store_categories'),
  ('20260821000300', 'stores'),
  ('20260821000400', 'backfill_stores_from_shop_name'),
  ('20260821000500', 'avatars_bucket'),
  ('20260821000600', 'drop_users_shop_name'),
  ('20260822000100', 'currencies'),
  ('20260822000200', 'currency_id'),
  ('20260822000300', 'drop_store_currency_text'),
  ('20260822000400', 'audit_timestamps'),
  ('20260822001100', 'register_existing_migrations')
on conflict (version) do nothing;
