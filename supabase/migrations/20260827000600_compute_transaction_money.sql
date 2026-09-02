-- §5.3, in two passes so a percent discount can never depend on itself and a
-- percent fee is always charged on the discounted amount. Rounding is half-up
-- to the store currency's minor units, applied once, at computation.
create or replace function public.compute_transaction_money(
  p_type                 text,
  p_lines                jsonb,
  p_fees                 jsonb,
  p_currency_minor_units int
) returns jsonb
language plpgsql
immutable
as $$
declare
  u int := coalesce(p_currency_minor_units, 2);
  items_subtotal     numeric(18,2) := 0;
  cogs               numeric(18,2) := 0;
  discount_total     numeric(18,2) := 0;
  buyer_charge_total numeric(18,2) := 0;
  seller_cost_total  numeric(18,2) := 0;
  pass_through_total numeric(18,2) := 0;
  buyer_total        numeric(18,2) := 0;
  net_revenue        numeric(18,2) := 0;
  gross_profit       numeric(18,2) := 0;
  net_profit         numeric(18,2) := 0;
  net_margin         numeric(9,6)  := 0;
  percent_base       numeric(18,2) := 0;
  fee                jsonb;
  amount             numeric(18,2);
  base               numeric(18,2);
  resolved           jsonb := '[]'::jsonb;
begin
  select coalesce(sum(round((l->>'lineGross')::numeric, u)), 0)
    into items_subtotal
    from jsonb_array_elements(coalesce(p_lines, '[]'::jsonb)) l;

  select coalesce(sum(round((l->>'lineCost')::numeric, u)), 0)
    into cogs
    from jsonb_array_elements(coalesce(p_lines, '[]'::jsonb)) l
   where (l->>'quantityDelta')::numeric < 0;

  -- Pass 1: discounts, against items_subtotal.
  for fee in select * from jsonb_array_elements(coalesce(p_fees, '[]'::jsonb)) loop
    if fee->>'direction' = 'discount' then
      if fee->>'kind' = 'percent' then
        base := items_subtotal;
        amount := round(items_subtotal * (fee->>'value')::numeric / 100, u);
      else
        base := null;
        amount := round((fee->>'value')::numeric, u);
      end if;
      discount_total := discount_total + amount;
      resolved := resolved || jsonb_build_object(
        'name', fee->>'name', 'direction', fee->>'direction', 'kind', fee->>'kind',
        'value', fee->>'value',
        'isPassThrough', coalesce((fee->>'isPassThrough')::boolean, false),
        'sortOrder', coalesce((fee->>'sortOrder')::int, 0),
        'computedAmount', amount::text, 'base', base::text);
    end if;
  end loop;

  -- Pass 2: everything else, on the post-discount base.
  percent_base := items_subtotal - discount_total;
  for fee in select * from jsonb_array_elements(coalesce(p_fees, '[]'::jsonb)) loop
    if fee->>'direction' <> 'discount' then
      if fee->>'kind' = 'percent' then
        base := percent_base;
        amount := round(percent_base * (fee->>'value')::numeric / 100, u);
      else
        base := null;
        amount := round((fee->>'value')::numeric, u);
      end if;
      if fee->>'direction' = 'buyer_charge' then
        buyer_charge_total := buyer_charge_total + amount;
        if coalesce((fee->>'isPassThrough')::boolean, false) then
          pass_through_total := pass_through_total + amount;
        end if;
      elsif fee->>'direction' = 'seller_cost' then
        seller_cost_total := seller_cost_total + amount;
      end if;
      resolved := resolved || jsonb_build_object(
        'name', fee->>'name', 'direction', fee->>'direction', 'kind', fee->>'kind',
        'value', fee->>'value',
        'isPassThrough', coalesce((fee->>'isPassThrough')::boolean, false),
        'sortOrder', coalesce((fee->>'sortOrder')::int, 0),
        'computedAmount', amount::text, 'base', base::text);
    end if;
  end loop;

  buyer_total  := items_subtotal + buyer_charge_total - discount_total;
  net_revenue  := buyer_total - pass_through_total - seller_cost_total;
  gross_profit := items_subtotal - discount_total - cogs;
  net_profit   := net_revenue - cogs;
  net_margin   := case when net_revenue = 0 then 0
                       else round(net_profit / net_revenue, 6) end;

  -- On a receive the shop is the buyer, so there is no revenue and no profit.
  if p_type = 'receive' then
    net_revenue := 0; gross_profit := 0; net_profit := 0; net_margin := 0;
  end if;

  -- A write_off or an adjust moves no money. cogs alone carries the value of
  -- what left, which is the figure the waste report reads.
  if p_type in ('write_off','adjust') then
    items_subtotal := 0; discount_total := 0; buyer_charge_total := 0;
    seller_cost_total := 0; pass_through_total := 0; buyer_total := 0;
    net_revenue := 0; gross_profit := 0; net_profit := 0; net_margin := 0;
  end if;

  -- Money leaves as decimal strings. A JSON number would be parsed as a double
  -- by every client, which is the drift numeric(18,2) exists to prevent.
  return jsonb_build_object(
    'items_subtotal',     items_subtotal::text,
    'discount_total',     discount_total::text,
    'buyer_charge_total', buyer_charge_total::text,
    'seller_cost_total',  seller_cost_total::text,
    'pass_through_total', pass_through_total::text,
    'buyer_total',        buyer_total::text,
    'net_revenue',        net_revenue::text,
    'cogs',               cogs::text,
    'gross_profit',       gross_profit::text,
    'net_profit',         net_profit::text,
    'net_margin',         net_margin::text,
    'fees',               resolved);
end;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000600', 'compute_transaction_money')
on conflict (version) do nothing;
