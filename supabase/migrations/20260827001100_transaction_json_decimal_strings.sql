-- The transaction in the exact shape the transactions Edge Function returns:
-- camelCase keys, timestamps in Z form, and every money and quantity column as
-- a decimal string. A JSON number would be parsed as a double by every client,
-- which is the drift numeric(18,2) and numeric(14,3) exist to prevent.
create or replace function public.transaction_json(p_id uuid)
returns jsonb
language sql
stable
as $$
  select jsonb_build_object(
    'id',                t.id,
    'storeId',           t.store_id,
    'type',              t.type,
    'code',              t.code,
    'occurredAt',        to_char(t.occurred_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'counterparty',      t.counterparty,
    'counterpartyPhone', t.counterparty_phone,
    'note',              t.note,
    'paymentMethod',     t.payment_method,
    'reason',            t.reason,
    'reasonNote',        t.reason_note,
    'itemsSubtotal',     t.items_subtotal::text,
    'discountTotal',     t.discount_total::text,
    'buyerChargeTotal',  t.buyer_charge_total::text,
    'sellerCostTotal',   t.seller_cost_total::text,
    'passThroughTotal',  t.pass_through_total::text,
    'buyerTotal',        t.buyer_total::text,
    'netRevenue',        t.net_revenue::text,
    'cogs',              t.cogs::text,
    'grossProfit',       t.gross_profit::text,
    'netProfit',         t.net_profit::text,
    'netMargin',         t.net_margin::text,
    'revision',          t.revision,
    'amendedAt',         case when t.amended_at is null then null
                         else to_char(t.amended_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') end,
    'createdAt',         to_char(t.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'updatedAt',         to_char(t.updated_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'deletedAt',         case when t.deleted_at is null then null
                         else to_char(t.deleted_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') end,
    'lines', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',               l.id,
        'transactionId',    l.transaction_id,
        'productId',        l.product_id,
        'batchId',          l.batch_id,
        'batchCode',        b.batch_code,
        'productName',      l.product_name_snapshot,
        'unit',             l.unit_snapshot,
        'quantityDelta',    l.quantity_delta::text,
        'unitPrice',        l.unit_price::text,
        'unitCostSnapshot', l.unit_cost_snapshot::text,
        'batchUnitCost',    b.unit_cost::text,
        'expiryDate',       case when b.expiry_date is null then null
                            else to_char(b.expiry_date, 'YYYY-MM-DD') end,
        'lineGross',        l.line_gross::text,
        'lineCost',         l.line_cost::text,
        'sortOrder',        l.sort_order,
        'createdAt',        to_char(l.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'updatedAt',        to_char(l.updated_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'deletedAt',        null
      ) order by l.sort_order)
        from public.transaction_lines l
        join public.batches b on b.id = l.batch_id
       where l.transaction_id = t.id and l.deleted_at is null), '[]'::jsonb),
    'fees', coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',             f.id,
        'transactionId',  f.transaction_id,
        'name',           f.name,
        'direction',      f.direction,
        'kind',           f.kind,
        'value',          f.value::text,
        'isPassThrough',  f.is_pass_through,
        'computedAmount', f.computed_amount::text,
        'sortOrder',      f.sort_order,
        'createdAt',      to_char(f.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'updatedAt',      to_char(f.updated_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'deletedAt',      null
      ) order by f.sort_order)
        from public.transaction_fees f
       where f.transaction_id = t.id and f.deleted_at is null), '[]'::jsonb))
    from public.transactions t
   where t.id = p_id;
$$;

-- The day subtotal is money, so it leaves as a decimal string too.
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
    -- A day's subtotal is NET money: what came in from sales less what went out
    -- to suppliers, so a delivery day reads negative and says so. A write-off
    -- and a stock count move no money and contribute nothing.
    select t.id, t.code, t.occurred_at,
           case when t.type = 'receive' then -t.buyer_total else t.buyer_total end
             as signed_total,
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
    select f.day, sum(f.signed_total) as subtotal, count(*) as day_count
      from filtered f
     where f.day in (select day from page_rows)
     group by f.day
  )
  select jsonb_build_object(
    'days', coalesce((
      select jsonb_agg(
               jsonb_build_object(
                 'date',             to_char(w.day, 'YYYY-MM-DD'),
                 'subtotal',         w.subtotal::text,
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
  ('20260827001100', 'transaction_json_decimal_strings')
on conflict (version) do nothing;
