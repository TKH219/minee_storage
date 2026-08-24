-- One product with the batches held in the store being viewed, in the exact
-- shape the products Edge Function returns.
create or replace function public.product_as_json(p_product_id uuid, p_store_id uuid)
returns jsonb
language sql
security invoker
stable
as $$
  select jsonb_build_object(
    'id',        p.id,
    'name',      p.name,
    'barcode',   p.barcode,
    'brand',     p.brand,
    'category',  p.category,
    'unit',      p.unit,
    'photoUrl',  p.image_url,
    'notes',     p.notes,
    'createdAt', to_char(p.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'updatedAt', to_char(p.updated_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
    'deletedAt', case when p.deleted_at is null then null
                 else to_char(p.deleted_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') end,
    'batches',   coalesce((
      select jsonb_agg(jsonb_build_object(
        'id',                b.id,
        'productId',         b.product_id,
        'storeId',           b.store_id,
        'batchCode',         b.batch_code,
        'initialQuantity',   b.quantity_received::text,
        'remainingQuantity', b.quantity_remaining::text,
        'unitPrice',         b.unit_cost::text,
        'expiryDate',        case when b.expiry_date is null then null
                             else to_char(b.expiry_date, 'YYYY-MM-DD') end,
        'purchasedAt',       to_char(b.received_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'supplier',          b.supplier,
        'storageLocation',   b.storage_location,
        'note',              b.note,
        'createdAt',         to_char(b.created_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'updatedAt',         to_char(b.updated_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"'),
        'deletedAt',         case when b.deleted_at is null then null
                             else to_char(b.deleted_at at time zone 'utc', 'YYYY-MM-DD"T"HH24:MI:SS"Z"') end
      ) order by b.expiry_date nulls last, b.received_at)
      from public.batches b
      where b.product_id = p.id and b.store_id = p_store_id and b.deleted_at is null
    ), '[]'::jsonb)
  )
  from public.products p
  where p.id = p_product_id;
$$;

create or replace function public.apply_consumption(
  p_product_id  uuid,
  p_store_id    uuid,
  p_allocations jsonb
)
returns jsonb
language plpgsql
security invoker
as $$
declare
  allocation   jsonb;
  batch_id     uuid;
  take         numeric(14,3);
  available    numeric(14,3);
  owning_store uuid;
begin
  if not exists (select 1 from public.products where id = p_product_id and deleted_at is null) then
    raise exception 'no_such_product' using errcode = 'P0002';
  end if;

  if jsonb_typeof(p_allocations) <> 'array' or jsonb_array_length(p_allocations) = 0 then
    raise exception 'empty_allocation' using errcode = '22023';
  end if;

  -- Validate every allocation before writing any of them. Partial fulfilment is
  -- never acceptable, so a stale line must leave all the others untouched.
  for allocation in select * from jsonb_array_elements(p_allocations) loop
    batch_id := (allocation ->> 'batchId')::uuid;
    take     := (allocation ->> 'quantity')::numeric;

    if take is null or take <= 0 then
      raise exception 'non_positive_quantity' using errcode = '22023';
    end if;

    select quantity_remaining, store_id into available, owning_store
      from public.batches
     where id = batch_id and product_id = p_product_id and deleted_at is null
       for update;

    if available is null then
      raise exception 'no_such_batch' using errcode = 'P0002';
    end if;
    if owning_store <> p_store_id then
      raise exception 'foreign_batch' using errcode = 'P0001';
    end if;
    if take > available then
      raise exception 'insufficient_stock' using errcode = 'P0003';
    end if;
  end loop;

  for allocation in select * from jsonb_array_elements(p_allocations) loop
    update public.batches
       set quantity_remaining = quantity_remaining - (allocation ->> 'quantity')::numeric
     where id = (allocation ->> 'batchId')::uuid;
  end loop;

  return public.product_as_json(p_product_id, p_store_id);
end;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260822001500', 'apply_consumption')
on conflict (version) do nothing;
