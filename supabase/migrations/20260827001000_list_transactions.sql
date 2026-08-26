-- The list paginates by transaction, so a busy day spans pages. Each day's
-- subtotal is therefore computed over the WHOLE filtered day and attached to
-- every page carrying a row from it; summing the visible rows on the device
-- would print a different number on page two than on page one.
create or replace function public.list_transactions(
  p_store_id       uuid,
  p_type           text        default null,
  p_from           timestamptz default null,
  p_to             timestamptz default null,
  p_product_id     uuid        default null,
  p_payment_method text        default null,
  p_q              text        default null,
  p_page           int         default 1,
  p_limit          int         default 20
) returns jsonb
language plpgsql
security invoker
stable
as $$
declare
  v_page   int := greatest(coalesce(p_page, 1), 1);
  v_limit  int := least(greatest(coalesce(p_limit, 20), 1), 100);
  v_offset int;
  v_result jsonb;
begin
  v_offset := (v_page - 1) * v_limit;

  with filtered as (
    select t.id, t.code, t.occurred_at, t.buyer_total,
           (t.occurred_at at time zone 'UTC')::date as day
      from public.transactions t
     where t.store_id = p_store_id
       and t.deleted_at is null
       and (p_type is null           or t.type = p_type)
       and (p_from is null           or t.occurred_at >= p_from)
       and (p_to is null             or t.occurred_at <= p_to)
       and (p_payment_method is null or t.payment_method = p_payment_method)
       and (p_q is null or p_q = ''  or t.code ilike '%' || p_q || '%'
                                     or coalesce(t.counterparty, '') ilike '%' || p_q || '%')
       and (p_product_id is null or exists (
             select 1 from public.transaction_lines l
              where l.transaction_id = t.id and l.deleted_at is null
                and l.product_id = p_product_id))
  ),
  page_rows as (
    select f.* from filtered f
     order by f.occurred_at desc, f.code desc
     offset v_offset limit v_limit
  ),
  whole_day as (
    select f.day, sum(f.buyer_total) as subtotal, count(*) as day_count
      from filtered f
     where f.day in (select day from page_rows)
     group by f.day
  )
  select jsonb_build_object(
    'days', coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'date',             w.day,
                 'subtotal',         w.subtotal,
                 'transactionCount', w.day_count,
                 'transactions', (
                   select coalesce(jsonb_agg(public.transaction_json(r.id)
                                             order by r.occurred_at desc, r.code desc), '[]'::jsonb)
                     from page_rows r where r.day = w.day))
               order by w.day desc)
        from whole_day w), '[]'::jsonb),
    'page',  v_page,
    'limit', v_limit,
    'total', (select count(*) from filtered))
  into v_result;

  return v_result;
end;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827001000', 'list_transactions')
on conflict (version) do nothing;
