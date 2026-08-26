import { SupabaseClient } from 'jsr:@supabase/supabase-js@2';

import { clientFor } from '../_shared/client.ts';
import { badRequest, failFromPostgres, PostgresError } from '../_shared/errors.ts';
import { fail, ok } from '../_shared/envelope.ts';

const DEFAULT_PAGE_SIZE = 20;

Deno.serve(async (request: Request) => {
  const supabase = clientFor(request);
  if (!supabase) return fail('UNAUTHORIZED', 'A bearer token is required.', 401);

  const url = new URL(request.url);
  const segments = url.pathname.split('/').filter(Boolean);
  const method = request.method;

  const txMarker = segments.indexOf('transactions');
  const feeMarker = segments.indexOf('fee-presets');

  try {
    if (feeMarker !== -1) {
      const after = segments.slice(feeMarker + 1);
      if (after.length === 0 && method === 'GET') return await listPresets(supabase, url);
      if (after.length === 0 && method === 'POST') return await createPreset(supabase, request);
      if (after.length === 1 && method === 'PATCH') return await updatePreset(supabase, after[0], request);
      if (after.length === 1 && method === 'DELETE') return await removePreset(supabase, after[0]);
      return fail('NOT_FOUND', 'No such route.', 404);
    }

    if (txMarker === -1) return fail('NOT_FOUND', 'No such route.', 404);
    const after = segments.slice(txMarker + 1);

    if (after.length === 0 && method === 'GET') return await listTransactions(supabase, url);
    if (after.length === 0 && method === 'POST') return await createTransaction(supabase, request);

    // Registered before the :id route so `preview` is never read as an id.
    if (after[0] === 'preview' && after.length === 1 && method === 'POST') {
      return await previewTransaction(supabase, request);
    }

    const id = after[0];
    if (after.length === 1 && method === 'GET') return await readTransaction(supabase, id);
    if (after.length === 1 && method === 'PUT') return await amendTransaction(supabase, id, request);
    if (after.length === 1 && method === 'DELETE') return await removeTransaction(supabase, id, request, url);

    return fail('NOT_FOUND', 'No such route.', 404);
  } catch (error) {
    return failFromPostgres(error as PostgresError);
  }
});

async function body(request: Request): Promise<Record<string, unknown>> {
  try {
    const parsed = await request.json();
    if (parsed && typeof parsed === 'object') return parsed as Record<string, unknown>;
  } catch (_) {
    // falls through to the same refusal an empty body earns
  }
  throw badRequest('A JSON body is required.');
}

function requireStoreFromQuery(url: URL): string {
  const storeId = url.searchParams.get('storeId');
  if (!storeId) throw badRequest('storeId is required.');
  return storeId;
}

function requireExpectedUpdatedAt(value: unknown): string {
  if (typeof value !== 'string' || value.length === 0) {
    throw badRequest('expectedUpdatedAt is required.');
  }
  return value;
}

function intParam(url: URL, name: string, fallback: number): number {
  const raw = url.searchParams.get(name);
  if (raw === null) return fallback;
  const parsed = Number.parseInt(raw, 10);
  if (Number.isNaN(parsed)) throw badRequest(`${name} must be a whole number.`);
  return parsed;
}

async function rpc(supabase: SupabaseClient, name: string, args: Record<string, unknown>) {
  const { data, error } = await supabase.rpc(name, args);
  if (error) throw error;
  return data;
}

async function listTransactions(supabase: SupabaseClient, url: URL) {
  const data = await rpc(supabase, 'list_transactions', {
    p_store_id: requireStoreFromQuery(url),
    p_type: url.searchParams.get('type'),
    p_from: url.searchParams.get('from'),
    p_to: url.searchParams.get('to'),
    p_product_id: url.searchParams.get('productId'),
    p_payment_method: url.searchParams.get('paymentMethod'),
    p_q: url.searchParams.get('q'),
    p_page: intParam(url, 'page', 1),
    p_limit: intParam(url, 'limit', DEFAULT_PAGE_SIZE),
  });
  return ok(data);
}

async function readTransaction(supabase: SupabaseClient, id: string) {
  const data = await rpc(supabase, 'transaction_json', { p_id: id });
  if (!data) return fail('NOT_FOUND', 'No such transaction.', 404);
  return ok(data);
}

async function createTransaction(supabase: SupabaseClient, request: Request) {
  const payload = await body(request);
  const data = await rpc(supabase, 'apply_transaction', { p_payload: payload });
  return ok(data, 201);
}

async function previewTransaction(supabase: SupabaseClient, request: Request) {
  const payload = await body(request);
  const data = await rpc(supabase, 'preview_transaction', { p_payload: payload });
  return ok(data);
}

async function amendTransaction(supabase: SupabaseClient, id: string, request: Request) {
  const payload = await body(request);
  const expected = requireExpectedUpdatedAt(payload.expectedUpdatedAt);
  delete payload.expectedUpdatedAt;
  const data = await rpc(supabase, 'amend_transaction', {
    p_id: id,
    p_payload: payload,
    p_expected_updated_at: expected,
  });
  return ok(data);
}

async function removeTransaction(
  supabase: SupabaseClient,
  id: string,
  request: Request,
  url: URL,
) {
  const fromQuery = url.searchParams.get('expectedUpdatedAt');
  const expected = fromQuery ?? requireExpectedUpdatedAt((await body(request)).expectedUpdatedAt);
  const data = await rpc(supabase, 'remove_transaction', {
    p_id: id,
    p_expected_updated_at: expected,
  });
  return ok(data);
}

async function listPresets(supabase: SupabaseClient, url: URL) {
  const { data, error } = await supabase
    .from('fee_presets')
    .select('*')
    .eq('store_id', requireStoreFromQuery(url))
    .is('deleted_at', null)
    .order('sort_order', { ascending: true });
  if (error) throw error;
  return ok(data ?? []);
}

async function createPreset(supabase: SupabaseClient, request: Request) {
  const payload = await body(request);
  const { data: user } = await supabase.auth.getUser();
  const { data, error } = await supabase
    .from('fee_presets')
    .insert({
      user_id: user?.user?.id,
      store_id: payload.storeId,
      name: payload.name,
      direction: payload.direction,
      kind: payload.kind,
      value: payload.value,
      is_pass_through: payload.isPassThrough ?? false,
      is_default: payload.isDefault ?? false,
      sort_order: payload.sortOrder ?? 0,
    })
    .select()
    .single();
  if (error) throw error;
  return ok(data, 201);
}

async function updatePreset(supabase: SupabaseClient, id: string, request: Request) {
  const payload = await body(request);
  const patch: Record<string, unknown> = {};
  if (payload.name !== undefined) patch.name = payload.name;
  if (payload.direction !== undefined) patch.direction = payload.direction;
  if (payload.kind !== undefined) patch.kind = payload.kind;
  if (payload.value !== undefined) patch.value = payload.value;
  if (payload.isPassThrough !== undefined) patch.is_pass_through = payload.isPassThrough;
  if (payload.isDefault !== undefined) patch.is_default = payload.isDefault;
  if (payload.sortOrder !== undefined) patch.sort_order = payload.sortOrder;
  if (Object.keys(patch).length === 0) throw badRequest('Nothing to update.');

  const { data, error } = await supabase
    .from('fee_presets')
    .update(patch)
    .eq('id', id)
    .is('deleted_at', null)
    .select()
    .single();
  if (error) throw error;
  if (!data) return fail('NOT_FOUND', 'No such fee preset.', 404);
  return ok(data);
}

async function removePreset(supabase: SupabaseClient, id: string) {
  const { data, error } = await supabase
    .from('fee_presets')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', id)
    .is('deleted_at', null)
    .select()
    .single();
  if (error) throw error;
  if (!data) return fail('NOT_FOUND', 'No such fee preset.', 404);
  return ok(data);
}
