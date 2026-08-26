create or replace function public.remove_transaction(
  p_id uuid, p_expected_updated_at timestamptz
) returns jsonb
language plpgsql
security invoker
as $$
declare
  v_txn record;
  v_lot record;
begin
  select * into v_txn from public.transactions
   where id = p_id and deleted_at is null for update;
  if v_txn.id is null then
    raise exception 'transaction % does not exist', p_id using errcode = 'P0002';
  end if;

  if v_txn.updated_at is distinct from p_expected_updated_at then
    raise exception 'transaction % moved underneath this delete', p_id using errcode = 'P0010';
  end if;

  if v_txn.type = 'receive' then
    -- A receive's lots may only be archived when nothing has been taken from
    -- them. Otherwise the delete is refused whole rather than half-applied.
    for v_lot in
      select b.id, b.batch_code, b.quantity_received, b.quantity_remaining
        from public.transaction_lines l
        join public.batches b on b.id = l.batch_id
       where l.transaction_id = p_id and l.deleted_at is null
       for update of b
    loop
      if v_lot.quantity_remaining <> v_lot.quantity_received then
        raise exception 'lot % has had % drawn out of it and cannot be undone; short by %',
          v_lot.batch_code, v_lot.quantity_received - v_lot.quantity_remaining,
          v_lot.quantity_received - v_lot.quantity_remaining using errcode = 'P0007';
      end if;
      if exists (
        select 1 from public.transaction_lines o
         where o.batch_id = v_lot.id and o.deleted_at is null and o.transaction_id <> p_id) then
        raise exception 'lot % is referenced by another transaction', v_lot.batch_code
          using errcode = 'P0009';
      end if;
    end loop;

    update public.batches set deleted_at = now(), quantity_remaining = 0
     where id in (select batch_id from public.transaction_lines
                   where transaction_id = p_id and deleted_at is null);
  else
    perform public.reverse_transaction_lines(p_id);
  end if;

  update public.transaction_lines set deleted_at = now()
   where transaction_id = p_id and deleted_at is null;
  update public.transaction_fees set deleted_at = now()
   where transaction_id = p_id and deleted_at is null;

  -- The code is never released. The unique index is partial on deleted_at, and
  -- next_transaction_code reads the highest ever issued.
  update public.transactions set deleted_at = now() where id = p_id;

  return public.transaction_json(p_id);
end;
$$;

insert into supabase_migrations.schema_migrations (version, name) values
  ('20260827000900', 'remove_transaction')
on conflict (version) do nothing;
