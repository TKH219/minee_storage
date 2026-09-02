-- Subtract every live line's delta from its batch. Reverse is the negation of
-- apply and shares its arithmetic; nothing here branches on type.
create or replace function public.reverse_transaction_lines(p_id uuid)
returns void
language plpgsql
as $$
declare
  v_line record;
  v_after numeric(14,3);
  v_received numeric(14,3);
begin
  for v_line in
    select l.id, l.batch_id, l.quantity_delta, b.quantity_remaining, b.quantity_received, b.batch_code
      from public.transaction_lines l
      join public.batches b on b.id = l.batch_id
     where l.transaction_id = p_id and l.deleted_at is null
     for update of b
  loop
    v_after := v_line.quantity_remaining - v_line.quantity_delta;
    if v_after < 0 then
      raise exception 'lot % holds % but % must come back out of it; short by %',
        v_line.batch_code, v_line.quantity_remaining, -v_line.quantity_delta,
        -v_after using errcode = 'P0007';
    end if;
    if v_after > v_line.quantity_received then
      raise exception 'lot % would hold % of only % received',
        v_line.batch_code, v_after, v_line.quantity_received using errcode = 'P0008';
    end if;
    update public.batches set quantity_remaining = v_after where id = v_line.batch_id;
  end loop;
end;
$$;

create or replace function public.amend_transaction(
  p_id uuid, p_payload jsonb, p_expected_updated_at timestamptz
) returns jsonb
language plpgsql
security invoker
as $$
declare
  v_txn      record;
  v_resolved jsonb;
  v_money    jsonb;
  v_occurred timestamptz;
  v_line     jsonb;
  v_fee      jsonb;
  v_old      record;
  v_newqty   numeric(14,3);
  v_drawn    numeric(14,3);
  v_units    int;
  v_idx      int := 0;
begin
  select * into v_txn from public.transactions
   where id = p_id and deleted_at is null for update;
  if v_txn.id is null then
    raise exception 'transaction % does not exist', p_id using errcode = 'P0002';
  end if;

  -- The lock is checked before anything moves, which is what makes the refusal
  -- total: a stale caller changes nothing at all.
  if v_txn.updated_at is distinct from p_expected_updated_at then
    raise exception 'transaction % moved underneath this edit', p_id using errcode = 'P0010';
  end if;

  v_occurred := coalesce((p_payload->>'occurredAt')::timestamptz, v_txn.occurred_at);

  if v_txn.type = 'receive' then
    -- A receive's lines create their batch rather than draw on one. Reversing
    -- and re-applying would strand the original lot and open a second for the
    -- same delivery, so the lot is amended where it stands.
    select coalesce(c.decimals, 2) into v_units
      from public.stores s left join public.currencies c on c.id = s.currency_id
     where s.id = v_txn.store_id;

    v_resolved := public.resolve_transaction_payload(
      p_payload || jsonb_build_object('storeId', v_txn.store_id, 'type', 'receive',
                                      'occurredAt', v_occurred));
    v_money := v_resolved->'money';

    for v_line in select * from jsonb_array_elements(v_resolved->'lines') loop
      select l.id, l.batch_id, b.quantity_received, b.quantity_remaining, b.batch_code
        into v_old
        from public.transaction_lines l
        join public.batches b on b.id = l.batch_id
       where l.transaction_id = p_id and l.deleted_at is null and l.sort_order = v_idx
       for update of b;

      v_newqty := (v_line->>'quantityDelta')::numeric;

      if v_old.id is null then
        -- A line added to an existing receive opens its own lot.
        insert into public.batches (
          product_id, store_id, batch_code, quantity_received, quantity_remaining,
          unit_cost, expiry_date, received_at, supplier, storage_location)
        values (
          (v_line->>'productId')::uuid, v_txn.store_id,
          nullif(v_line->'batch'->>'batchCode',''), v_newqty, v_newqty,
          (v_line->>'unitCostSnapshot')::numeric,
          (v_line->'batch'->>'expiryDate')::date, v_occurred,
          v_line->'batch'->>'supplier', v_line->'batch'->>'storageLocation');
      else
        v_drawn := v_old.quantity_received - v_old.quantity_remaining;
        if v_newqty < v_drawn then
          raise exception 'lot % has already had % drawn out of it, so it cannot hold only %; short by %',
            v_old.batch_code, v_drawn, v_newqty, v_drawn - v_newqty using errcode = 'P0004';
        end if;
        update public.batches
           set quantity_received  = v_newqty,
               quantity_remaining = v_old.quantity_remaining + (v_newqty - v_old.quantity_received),
               unit_cost          = (v_line->>'unitCostSnapshot')::numeric,
               expiry_date        = coalesce((v_line->'batch'->>'expiryDate')::date, expiry_date),
               supplier           = coalesce(v_line->'batch'->>'supplier', supplier),
               storage_location   = coalesce(v_line->'batch'->>'storageLocation', storage_location),
               received_at        = v_occurred
         where id = v_old.batch_id;
      end if;
      v_idx := v_idx + 1;
    end loop;

    -- A line removed from a receive takes its lot with it, under the same
    -- untouched-only rule a delete obeys.
    for v_old in
      select l.id, l.batch_id, b.quantity_received, b.quantity_remaining, b.batch_code
        from public.transaction_lines l
        join public.batches b on b.id = l.batch_id
       where l.transaction_id = p_id and l.deleted_at is null and l.sort_order >= v_idx
    loop
      if v_old.quantity_remaining <> v_old.quantity_received then
        raise exception 'lot % has already been drawn from and cannot be removed',
          v_old.batch_code using errcode = 'P0009';
      end if;
      update public.batches set deleted_at = now() where id = v_old.batch_id;
    end loop;

  else
    -- Put the stock back first, so FEFO re-resolves against the shelf as it
    -- stands with the reversed quantity already on it.
    perform public.reverse_transaction_lines(p_id);
    v_resolved := public.resolve_transaction_payload(
      p_payload || jsonb_build_object('storeId', v_txn.store_id, 'type', v_txn.type,
                                      'occurredAt', v_occurred));
    v_money := v_resolved->'money';
  end if;

  -- The superseded rows are soft-deleted, never overwritten, so reconstructing
  -- an earlier revision stays a query.
  update public.transaction_lines set deleted_at = now()
   where transaction_id = p_id and deleted_at is null;
  update public.transaction_fees set deleted_at = now()
   where transaction_id = p_id and deleted_at is null;

  if v_txn.type = 'receive' then
    v_idx := 0;
    for v_line in select * from jsonb_array_elements(v_resolved->'lines') loop
      insert into public.transaction_lines (
        transaction_id, product_id, batch_id, product_name_snapshot, unit_snapshot,
        quantity_delta, unit_price, unit_cost_snapshot, line_gross, line_cost, sort_order)
      select p_id, (v_line->>'productId')::uuid, b.id,
             v_line->>'productName', v_line->>'unit',
             (v_line->>'quantityDelta')::numeric, (v_line->>'unitPrice')::numeric,
             (v_line->>'unitCostSnapshot')::numeric,
             (v_line->>'lineGross')::numeric, (v_line->>'lineCost')::numeric, v_idx
        from public.batches b
       where b.product_id = (v_line->>'productId')::uuid
         and b.store_id = v_txn.store_id and b.deleted_at is null
         and b.received_at = v_occurred
       order by b.created_at desc limit 1;
      v_idx := v_idx + 1;
    end loop;
  else
    perform public.write_transaction_lines(p_id, v_txn.store_id, v_resolved);
  end if;

  for v_fee in select * from jsonb_array_elements(v_money->'fees') loop
    insert into public.transaction_fees
      (transaction_id, name, direction, kind, value, is_pass_through, computed_amount, sort_order)
    values (p_id, v_fee->>'name', v_fee->>'direction', v_fee->>'kind',
            (v_fee->>'value')::numeric,
            coalesce((v_fee->>'isPassThrough')::boolean, false),
            (v_fee->>'computedAmount')::numeric,
            coalesce((v_fee->>'sortOrder')::int, 0));
  end loop;

  update public.transactions set
    occurred_at        = v_occurred,
    counterparty       = p_payload->>'counterparty',
    counterparty_phone = p_payload->>'counterpartyPhone',
    note               = p_payload->>'note',
    payment_method     = coalesce(p_payload->>'paymentMethod', payment_method),
    reason             = coalesce(p_payload->>'reason', reason),
    reason_note        = p_payload->>'reasonNote',
    items_subtotal     = (v_money->>'items_subtotal')::numeric,
    discount_total     = (v_money->>'discount_total')::numeric,
    buyer_charge_total = (v_money->>'buyer_charge_total')::numeric,
    seller_cost_total  = (v_money->>'seller_cost_total')::numeric,
    pass_through_total = (v_money->>'pass_through_total')::numeric,
    buyer_total        = (v_money->>'buyer_total')::numeric,
    net_revenue        = (v_money->>'net_revenue')::numeric,
    cogs               = (v_money->>'cogs')::numeric,
    gross_profit       = (v_money->>'gross_profit')::numeric,
    net_profit         = (v_money->>'net_profit')::numeric,
    net_margin         = (v_money->>'net_margin')::numeric,
    amended_at         = now(),
    revision           = revision + 1
  where id = p_id;

  return public.transaction_json(p_id);
end;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000800', 'amend_transaction')
on conflict (version) do nothing;
