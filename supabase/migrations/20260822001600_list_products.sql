-- Paging and the expiry chips have to agree, and "expiring soon" is derived
-- from the batches held in the store being viewed - not a column PostgREST can
-- filter on. Computing it here is what keeps hasMore and the page size honest;
-- filtering after the page has been cut would silently shorten pages.
create or replace function public.list_products(
  p_store_id uuid,
  p_status   text default 'all',
  p_search   text default null,
  p_category text default null,
  p_page     int  default 1,
  p_limit    int  default 20
)
returns jsonb
language sql
security invoker
stable
as $$
  with base as (
    select p.id,
           p.created_at,
           (select min(b.expiry_date)
              from public.batches b
             where b.product_id = p.id
               and b.store_id = p_store_id
               and b.deleted_at is null
               and b.quantity_remaining > 0) as nearest_expiry
      from public.products p
     where (case when p_status = 'archived'
                 then p.deleted_at is not null
                 else p.deleted_at is null end)
       and (p_search   is null or p.name ilike '%' || p_search || '%')
       and (p_category is null or p.category = p_category)
  ),
  filtered as (
    select * from base
     where case p_status
             when 'expired' then
               nearest_expiry is not null and nearest_expiry <= current_date
             when 'expiringSoon' then
               nearest_expiry is not null
               and nearest_expiry >  current_date
               and nearest_expiry <= current_date + 30
             else true
           end
  ),
  window_rows as (
    select id, created_at
      from filtered
     order by created_at desc
     offset (greatest(p_page, 1) - 1) * p_limit
     limit p_limit + 1
  ),
  page_rows as (
    select id, created_at from window_rows order by created_at desc limit p_limit
  )
  select jsonb_build_object(
    'items', coalesce(
      (select jsonb_agg(public.product_as_json(id, p_store_id) order by created_at desc)
         from page_rows), '[]'::jsonb),
    'hasMore', (select count(*) from window_rows) > p_limit
  );
$$;

-- Distinct category values the caller has already used, for the autocomplete.
create or replace function public.list_product_categories()
returns jsonb
language sql
security invoker
stable
as $$
  select coalesce(jsonb_agg(category order by category), '[]'::jsonb)
    from (select distinct category
            from public.products
           where deleted_at is null and category is not null and btrim(category) <> '') t;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260822001600', 'list_products')
on conflict (version) do nothing;
