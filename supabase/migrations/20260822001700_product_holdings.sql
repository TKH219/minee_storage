-- What the same product holds in the caller's other shops.
--
-- product_as_json is deliberately scoped to one store, so detail has no way to
-- answer "where else is this?" without a second call. RLS still applies, so a
-- caller only ever sees their own stores.
create or replace function public.product_store_holdings(p_product_id uuid)
returns jsonb
language sql
security invoker
stable
as $$
  select coalesce(jsonb_agg(row order by row ->> 'storeName'), '[]'::jsonb)
    from (
      select jsonb_build_object(
               'storeId',   s.id,
               'storeName', s.name,
               'remaining', sum(b.quantity_remaining)::text,
               'latestUnitPrice', (
                 select b2.unit_cost::text
                   from public.batches b2
                  where b2.product_id = p_product_id
                    and b2.store_id = s.id
                    and b2.deleted_at is null
                  order by b2.received_at desc
                  limit 1
               )
             ) as row
        from public.batches b
        join public.stores s on s.id = b.store_id
       where b.product_id = p_product_id
         and b.deleted_at is null
         and s.deleted_at is null
       group by s.id, s.name
      having sum(b.quantity_remaining) > 0
    ) rows;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260822001700', 'product_holdings')
on conflict (version) do nothing;
