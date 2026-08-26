-- Resolve a payload into concrete lines, fees and money without writing.
-- apply_transaction, amend_transaction and preview_transaction all call this,
-- which is what keeps the previewed total and the stored total the same number.
create or replace function public.resolve_transaction_payload(p_payload jsonb)
returns jsonb
language plpgsql
as $$
declare
  v_store   uuid := (p_payload->>'storeId')::uuid;
  v_type    text := p_payload->>'type';
  v_units   int;
  v_line    jsonb;
  v_idx     int := 0;
  v_lines   jsonb := '[]'::jsonb;
  v_money   jsonb;
  v_fee     jsonb;
  v_pid     uuid;
  v_bid     uuid;
  v_qty     numeric(14,3);
  v_price   numeric(18,2);
  v_pname   text;
  v_punit   text;
  v_bcost   numeric(18,2);
  v_brem    numeric(14,3);
  v_take    numeric(14,3);
  v_out     numeric(14,3);
  v_avail   numeric(14,3);
  v_delta   numeric(14,3);
  v_gross   numeric(18,2);
  v_batch   record;
  v_bearable numeric(18,2);
  v_grosstot numeric(18,2);
  v_share   numeric(18,2);
  v_landed  numeric(18,2);
  v_new     jsonb := '[]'::jsonb;
begin
  if v_type not in ('sale','receive','write_off','adjust') then
    raise exception 'unknown transaction type %', v_type using errcode = '22023';
  end if;

  select coalesce(c.decimals, 2) into v_units
    from public.stores s left join public.currencies c on c.id = s.currency_id
   where s.id = v_store;
  if v_units is null then
    raise exception 'store % does not exist', v_store using errcode = 'P0002';
  end if;

  if v_type in ('write_off','adjust') and jsonb_array_length(coalesce(p_payload->'fees','[]'::jsonb)) > 0 then
    raise exception 'a % carries no fees', v_type using errcode = 'P0006';
  end if;
  if v_type = 'receive' then
    for v_fee in select * from jsonb_array_elements(coalesce(p_payload->'fees','[]'::jsonb)) loop
      if v_fee->>'direction' = 'seller_cost' then
        raise exception 'a receive has no seller side' using errcode = 'P0006';
      end if;
    end loop;
  end if;

  for v_line in select * from jsonb_array_elements(coalesce(p_payload->'lines','[]'::jsonb)) loop
    v_pid   := (v_line->>'productId')::uuid;
    v_qty   := (v_line->>'quantity')::numeric;
    v_price := coalesce((v_line->>'unitPrice')::numeric, 0);

    select name, unit into v_pname, v_punit from public.products where id = v_pid and deleted_at is null;
    if v_pname is null then
      raise exception 'product % does not exist', v_pid using errcode = 'P0002';
    end if;

    if v_type = 'receive' then
      if v_qty <= 0 then
        raise exception 'a receive must bring in a positive quantity' using errcode = '22023';
      end if;
      v_gross := round(v_qty * v_price, v_units);
      v_lines := v_lines || jsonb_build_object(
        'productId', v_pid, 'batchId', null,
        'productName', v_pname, 'unit', v_punit,
        'quantityDelta', v_qty, 'unitPrice', v_price,
        'unitCostSnapshot', v_price, 'lineGross', v_gross, 'lineCost', v_gross,
        'sortOrder', v_idx, 'batch', coalesce(v_line->'batch', '{}'::jsonb));
      v_idx := v_idx + 1;

    elsif v_type = 'adjust' then
      v_bid := (v_line->>'batchId')::uuid;
      if v_bid is null then
        raise exception 'a stock count names the lot it counted' using errcode = '22023';
      end if;
      select unit_cost, quantity_remaining into v_bcost, v_brem
        from public.batches where id = v_bid and deleted_at is null;
      if v_bcost is null then
        raise exception 'batch % does not exist', v_bid using errcode = 'P0002';
      end if;
      -- The stock was always there; the record was wrong. No purchase happened,
      -- so the lot's existing cost is the only cost there is to learn.
      v_delta := v_qty - v_brem;
      if v_delta = 0 then
        raise exception 'the count matches the record, so nothing moved' using errcode = '22023';
      end if;
      v_lines := v_lines || jsonb_build_object(
        'productId', v_pid, 'batchId', v_bid,
        'productName', v_pname, 'unit', v_punit,
        'quantityDelta', v_delta, 'unitPrice', 0,
        'unitCostSnapshot', v_bcost, 'lineGross', 0,
        'lineCost', round(abs(v_delta) * v_bcost, v_units),
        'sortOrder', v_idx, 'batch', '{}'::jsonb);
      v_idx := v_idx + 1;

    else
      if v_qty <= 0 then
        raise exception 'a % must move a positive quantity', v_type using errcode = '22023';
      end if;
      v_bid := (v_line->>'batchId')::uuid;
      v_out := v_qty;

      if v_bid is not null then
        select unit_cost, quantity_remaining into v_bcost, v_brem
          from public.batches where id = v_bid and deleted_at is null;
        if v_bcost is null then
          raise exception 'batch % does not exist', v_bid using errcode = 'P0002';
        end if;
        if v_brem < v_qty then
          raise exception 'lot % holds % but % was asked for', v_bid, v_brem, v_qty
            using errcode = 'P0003';
        end if;
        v_gross := case when v_type = 'sale' then round(v_qty * v_price, v_units) else 0 end;
        v_lines := v_lines || jsonb_build_object(
          'productId', v_pid, 'batchId', v_bid,
          'productName', v_pname, 'unit', v_punit,
          'quantityDelta', -v_qty, 'unitPrice', v_price,
          'unitCostSnapshot', v_bcost, 'lineGross', v_gross,
          'lineCost', round(v_qty * v_bcost, v_units),
          'sortOrder', v_idx, 'batch', '{}'::jsonb);
        v_idx := v_idx + 1;
      else
        select coalesce(sum(quantity_remaining), 0) into v_avail
          from public.batches
         where product_id = v_pid and store_id = v_store
           and deleted_at is null and quantity_remaining > 0;
        if v_avail < v_qty then
          raise exception 'only % of % available', v_avail, v_qty using errcode = 'P0003';
        end if;
        -- First expire, first out: expiry ascending with undated lots last,
        -- then by arrival. The same order FefoAllocator uses on the device.
        for v_batch in
          select id, unit_cost, quantity_remaining
            from public.batches
           where product_id = v_pid and store_id = v_store
             and deleted_at is null and quantity_remaining > 0
           order by expiry_date asc nulls last, received_at asc, id asc
        loop
          exit when v_out <= 0;
          v_take := least(v_out, v_batch.quantity_remaining);
          v_gross := case when v_type = 'sale' then round(v_take * v_price, v_units) else 0 end;
          v_lines := v_lines || jsonb_build_object(
            'productId', v_pid, 'batchId', v_batch.id,
            'productName', v_pname, 'unit', v_punit,
            'quantityDelta', -v_take, 'unitPrice', v_price,
            'unitCostSnapshot', v_batch.unit_cost, 'lineGross', v_gross,
            'lineCost', round(v_take * v_batch.unit_cost, v_units),
            'sortOrder', v_idx, 'batch', '{}'::jsonb);
          v_idx := v_idx + 1;
          v_out := v_out - v_take;
        end loop;
      end if;
    end if;
  end loop;

  if jsonb_array_length(v_lines) = 0 then
    raise exception 'a transaction moves at least one line' using errcode = '22023';
  end if;

  v_money := public.compute_transaction_money(
    v_type, v_lines, coalesce(p_payload->'fees','[]'::jsonb), v_units);

  -- Landed cost: every fee the shop actually bears, apportioned across the
  -- lines pro-rata by line_gross and folded into what the goods cost. A
  -- pass-through fee is excluded -- the shop gets it back, so it was never
  -- part of the cost of the goods.
  if v_type = 'receive' then
    v_bearable := 0;
    for v_fee in select * from jsonb_array_elements(v_money->'fees') loop
      if v_fee->>'direction' = 'buyer_charge'
         and not coalesce((v_fee->>'isPassThrough')::boolean, false) then
        v_bearable := v_bearable + (v_fee->>'computedAmount')::numeric;
      elsif v_fee->>'direction' = 'discount' then
        v_bearable := v_bearable - (v_fee->>'computedAmount')::numeric;
      end if;
    end loop;

    v_grosstot := (v_money->>'items_subtotal')::numeric;
    if v_bearable <> 0 and v_grosstot > 0 then
      for v_line in select * from jsonb_array_elements(v_lines) loop
        v_gross := (v_line->>'lineGross')::numeric;
        v_qty   := (v_line->>'quantityDelta')::numeric;
        v_share := round(v_bearable * v_gross / v_grosstot, v_units);
        v_landed := round((v_gross + v_share) / v_qty, 2);
        v_new := v_new || (v_line
          || jsonb_build_object('unitCostSnapshot', v_landed,
                                'lineCost', round(v_qty * v_landed, v_units),
                                'landedShare', v_share));
      end loop;
      v_lines := v_new;
    end if;
  end if;

  return jsonb_build_object(
    'storeId', v_store, 'type', v_type,
    'occurredAt', coalesce((p_payload->>'occurredAt')::timestamptz, now()),
    'currencyMinorUnits', v_units,
    'lines', v_lines, 'money', v_money);
end;
$$;

-- Resolve allocation and money without writing. Backs the running-total bar
-- and the amend diff.
create or replace function public.preview_transaction(p_payload jsonb)
returns jsonb
language sql
security invoker
as $$
  select public.resolve_transaction_payload(p_payload);
$$;

create or replace function public.apply_transaction(p_payload jsonb)
returns jsonb
language plpgsql
security invoker
as $$
declare
  v_resolved jsonb;
  v_money    jsonb;
  v_store    uuid := (p_payload->>'storeId')::uuid;
  v_type     text := p_payload->>'type';
  v_occurred timestamptz := coalesce((p_payload->>'occurredAt')::timestamptz, now());
  v_id       uuid;
  v_line     jsonb;
  v_fee      jsonb;
  v_bid      uuid;
  v_qty      numeric(14,3);
  v_code     text;
begin
  v_resolved := public.resolve_transaction_payload(p_payload);
  v_money    := v_resolved->'money';
  v_code     := public.next_transaction_code(v_store, v_type, v_occurred);

  insert into public.transactions (
    user_id, store_id, type, code, occurred_at,
    counterparty, counterparty_phone, note, payment_method, reason, reason_note,
    items_subtotal, discount_total, buyer_charge_total, seller_cost_total,
    pass_through_total, buyer_total, net_revenue, cogs, gross_profit,
    net_profit, net_margin)
  values (
    auth.uid(), v_store, v_type, v_code, v_occurred,
    p_payload->>'counterparty', p_payload->>'counterpartyPhone', p_payload->>'note',
    p_payload->>'paymentMethod', p_payload->>'reason', p_payload->>'reasonNote',
    (v_money->>'items_subtotal')::numeric, (v_money->>'discount_total')::numeric,
    (v_money->>'buyer_charge_total')::numeric, (v_money->>'seller_cost_total')::numeric,
    (v_money->>'pass_through_total')::numeric, (v_money->>'buyer_total')::numeric,
    (v_money->>'net_revenue')::numeric, (v_money->>'cogs')::numeric,
    (v_money->>'gross_profit')::numeric, (v_money->>'net_profit')::numeric,
    (v_money->>'net_margin')::numeric)
  returning id into v_id;

  perform public.write_transaction_lines(v_id, v_store, v_resolved);

  for v_fee in select * from jsonb_array_elements(v_money->'fees') loop
    insert into public.transaction_fees
      (transaction_id, name, direction, kind, value, is_pass_through, computed_amount, sort_order)
    values (v_id, v_fee->>'name', v_fee->>'direction', v_fee->>'kind',
            (v_fee->>'value')::numeric,
            coalesce((v_fee->>'isPassThrough')::boolean, false),
            (v_fee->>'computedAmount')::numeric,
            coalesce((v_fee->>'sortOrder')::int, 0));
  end loop;

  return public.transaction_json(v_id);
end;
$$;

-- Create a receive's batches, apply every delta, and insert the lines. Applying
-- is addition and nothing here branches on type -- the sign already carries it.
create or replace function public.write_transaction_lines(
  p_transaction_id uuid, p_store_id uuid, p_resolved jsonb
) returns void
language plpgsql
as $$
declare
  v_line jsonb;
  v_bid  uuid;
  v_qty  numeric(14,3);
  v_type text := p_resolved->>'type';
begin
  for v_line in select * from jsonb_array_elements(p_resolved->'lines') loop
    v_qty := (v_line->>'quantityDelta')::numeric;
    v_bid := (v_line->>'batchId')::uuid;

    if v_bid is null then
      insert into public.batches (
        product_id, store_id, batch_code, quantity_received, quantity_remaining,
        unit_cost, expiry_date, received_at, supplier, storage_location, note)
      values (
        (v_line->>'productId')::uuid, p_store_id,
        nullif(v_line->'batch'->>'batchCode', ''),
        v_qty, v_qty,
        (v_line->>'unitCostSnapshot')::numeric,
        (v_line->'batch'->>'expiryDate')::date,
        coalesce((v_line->'batch'->>'receivedAt')::timestamptz,
                 (p_resolved->>'occurredAt')::timestamptz, now()),
        v_line->'batch'->>'supplier',
        v_line->'batch'->>'storageLocation',
        v_line->'batch'->>'note')
      returning id into v_bid;
    else
      begin
        update public.batches
           set quantity_remaining = quantity_remaining + v_qty
         where id = v_bid;
      exception when check_violation then
        raise exception 'lot % cannot move by %', v_bid, v_qty using errcode = 'P0007';
      end;
    end if;

    insert into public.transaction_lines (
      transaction_id, product_id, batch_id, product_name_snapshot, unit_snapshot,
      quantity_delta, unit_price, unit_cost_snapshot, line_gross, line_cost, sort_order)
    values (
      p_transaction_id, (v_line->>'productId')::uuid, v_bid,
      v_line->>'productName', v_line->>'unit',
      v_qty, (v_line->>'unitPrice')::numeric,
      (v_line->>'unitCostSnapshot')::numeric,
      (v_line->>'lineGross')::numeric, (v_line->>'lineCost')::numeric,
      (v_line->>'sortOrder')::int);
  end loop;
end;
$$;

create or replace function public.transaction_json(p_id uuid)
returns jsonb
language sql
stable
as $$
  select to_jsonb(t) || jsonb_build_object(
    'lines', coalesce((
      select jsonb_agg(to_jsonb(l) order by l.sort_order)
        from public.transaction_lines l
       where l.transaction_id = t.id and l.deleted_at is null), '[]'::jsonb),
    'fees', coalesce((
      select jsonb_agg(to_jsonb(f) order by f.sort_order)
        from public.transaction_fees f
       where f.transaction_id = t.id and f.deleted_at is null), '[]'::jsonb))
    from public.transactions t
   where t.id = p_id;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000700', 'apply_transaction')
on conflict (version) do nothing;
