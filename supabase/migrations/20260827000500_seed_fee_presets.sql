insert into public.fee_presets
  (user_id, store_id, name, direction, kind, value, is_pass_through, is_default, sort_order)
select s.owner_id, s.id, 'VAT', 'buyer_charge', 'percent', 10, true, true, 0
  from public.stores s
 where not exists (
   select 1 from public.fee_presets f
    where f.store_id = s.id and f.name = 'VAT' and f.deleted_at is null);

insert into public.fee_presets
  (user_id, store_id, name, direction, kind, value, is_pass_through, is_default, sort_order)
select s.owner_id, s.id, 'Shipping', 'buyer_charge', 'fixed', 0, false, false, 1
  from public.stores s
 where not exists (
   select 1 from public.fee_presets f
    where f.store_id = s.id and f.name = 'Shipping' and f.deleted_at is null);

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000500', 'seed_fee_presets')
on conflict (version) do nothing;
