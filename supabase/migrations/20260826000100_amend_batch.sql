-- Editing a lot corrects what came in, never what is left. The remainder is
-- moved only by a stock transaction, so here it follows the received quantity
-- by the same delta: correcting a delivery of 20 up to 25 leaves 5 more on the
-- shelf, and nothing else about the edit touches stock.
create or replace function public.amend_batch(
  p_product_id       uuid,
  p_batch_id         uuid,
  p_store_id         uuid,
  p_quantity_received numeric,
  p_unit_cost        numeric,
  p_received_at      timestamptz,
  p_expiry_date      date,
  p_supplier         text,
  p_storage_location text,
  p_note             text
)
returns jsonb
language plpgsql
security invoker
as $$
declare drawn numeric;
begin
  select quantity_received - quantity_remaining
    into drawn
    from public.batches
   where id = p_batch_id and product_id = p_product_id and deleted_at is null
     for update;

  if drawn is null then
    raise exception 'no_such_batch' using errcode = 'P0002';
  end if;

  -- Below this the remainder would have to go negative, which only an
  -- unrecorded movement could explain. Refused rather than balanced.
  if p_quantity_received < drawn then
    raise exception 'quantity_below_drawn: % already drawn out', drawn
      using errcode = 'P0004';
  end if;

  update public.batches
     set quantity_received  = p_quantity_received,
         quantity_remaining = p_quantity_received - drawn,
         unit_cost          = p_unit_cost,
         received_at        = p_received_at,
         expiry_date        = p_expiry_date,
         supplier           = p_supplier,
         storage_location   = p_storage_location,
         note               = p_note
   where id = p_batch_id and product_id = p_product_id;

  return public.product_as_json(p_product_id, p_store_id);
end;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260826000100', 'amend_batch')
on conflict (version) do nothing;
