create schema if not exists supabase_migrations;

create table if not exists supabase_migrations.schema_migrations (
  version     text primary key,
  name        text,
  statements  text[],
  inserted_at timestamptz not null default now()
);

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260809000100', 'create_users'),
  ('20260809000200', 'email_status'),
  ('20260821000000', 'migration_history')
on conflict (version) do nothing;
