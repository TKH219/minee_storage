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
  const marker = segments.indexOf('products');
  const after = marker === -1 ? [] : segments.slice(marker + 1);
  const method = request.method;

  try {
    if (after.length === 0 && method === 'GET') return await listProducts(supabase, url);
    if (after.length === 0 && method === 'POST') return await createProduct(supabase, request);

    if (after[0] === 'categories' && after.length === 1 && method === 'GET') {
      return await listCategories(supabase);
    }
    if (after[0] === 'barcode' && after.length === 2 && method === 'GET') {
      return await byBarcode(supabase, decodeURIComponent(after[1]), url);
    }

    const id = after[0];
    if (after.length === 1 && method === 'GET') return await readProduct(supabase, id, url);
    if (after.length === 1 && method === 'PATCH') return await updateProduct(supabase, id, request);

    if (after.length === 2 && after[1] === 'archive' && method === 'POST') {
      return await setDeletedAt(supabase, id, new Date().toISOString(), url);
    }
    if (after.length === 2 && after[1] === 'restore' && method === 'POST') {
      return await setDeletedAt(supabase, id, null, url);
    }
    if (after.length === 2 && after[1] === 'batches' && method === 'POST') {
      return await addBatch(supabase, id, request);
    }
    if (after.length === 3 && after[1] === 'batches' && method === 'PATCH') {
      return await updateBatch(supabase, id, after[2], request);
    }
    if (after.length === 4 && after[1] === 'batches' && after[3] === 'archive' && method === 'POST') {
      return await archiveBatch(supabase, id, after[2], url);
    }
    if (after.length === 2 && after[1] === 'consumptions' && method === 'POST') {
      return await consume(supabase, id, request);
    }

    return fail('NOT_FOUND', 'No such route.', 404);
  } catch (error) {
    return failFromPostgres(error as PostgresError);
  }
});

function requireStoreFromQuery(url: URL): string {
  const storeId = url.searchParams.get('storeId');
  if (!storeId) throw badRequest('storeId is required.');
  return storeId;
}

function requireStoreFromBody(body: Record<string, unknown>): string {
  const storeId = body.storeId;
  if (typeof storeId !== 'string' || storeId.length === 0) {
    throw badRequest('storeId is required.');
  }
  return storeId;
}

async function productJson(supabase: SupabaseClient, id: string, storeId: string) {
  const { data, error } = await supabase.rpc('product_as_json', {
    p_product_id: id,
    p_store_id: storeId,
  });
  if (error) throw error;
  if (!data) throw { code: 'P0002', message: 'No such product.' };
  return data;
}

async function listProducts(supabase: SupabaseClient, url: URL) {
  const { data, error } = await supabase.rpc('list_products', {
    p_store_id: requireStoreFromQuery(url),
    p_status: url.searchParams.get('status') ?? 'all',
    p_search: url.searchParams.get('search'),
    p_category: url.searchParams.get('category'),
    p_page: Number(url.searchParams.get('page') ?? '1'),
    p_limit: Number(url.searchParams.get('limit') ?? String(DEFAULT_PAGE_SIZE)),
  });
  if (error) throw error;
  return ok(data);
}

async function listCategories(supabase: SupabaseClient) {
  const { data, error } = await supabase.rpc('list_product_categories');
  if (error) throw error;
  return ok(data);
}

function productColumns(body: Record<string, unknown>) {
  return {
    name: body.name,
    barcode: body.barcode ?? null,
    brand: body.brand ?? null,
    category: body.category ?? null,
    unit: body.unit ?? 'piece',
    image_url: body.photoUrl ?? null,
    notes: body.notes ?? null,
  };
}

async function createProduct(supabase: SupabaseClient, request: Request) {
  const body = await request.json();
  const storeId = requireStoreFromBody(body);

  const { data: session } = await supabase.auth.getUser();
  if (!session.user) return fail('UNAUTHORIZED', 'A bearer token is required.', 401);

  const { data, error } = await supabase
    .from('products')
    .insert({ user_id: session.user.id, ...productColumns(body) })
    .select('id')
    .single();
  if (error) throw error;

  return ok(await productJson(supabase, data.id, storeId), 201);
}

async function updateProduct(supabase: SupabaseClient, id: string, request: Request) {
  const body = await request.json();
  const storeId = requireStoreFromBody(body);

  const { error } = await supabase.from('products').update(productColumns(body)).eq('id', id);
  if (error) throw error;

  return ok(await productJson(supabase, id, storeId));
}

async function readProduct(supabase: SupabaseClient, id: string, url: URL) {
  return ok(await productJson(supabase, id, requireStoreFromQuery(url)));
}

async function setDeletedAt(
  supabase: SupabaseClient,
  id: string,
  value: string | null,
  url: URL,
) {
  const storeId = requireStoreFromQuery(url);
  const { error } = await supabase.from('products').update({ deleted_at: value }).eq('id', id);
  if (error) throw error;
  return ok(await productJson(supabase, id, storeId));
}

async function byBarcode(supabase: SupabaseClient, barcode: string, url: URL) {
  const storeId = requireStoreFromQuery(url);
  const { data, error } = await supabase
    .from('products')
    .select('id')
    .eq('barcode', barcode)
    .is('deleted_at', null)
    .maybeSingle();
  if (error) throw error;
  if (!data) return fail('NOT_FOUND', 'No product carries this barcode.', 404);
  return ok(await productJson(supabase, data.id, storeId));
}

function batchColumns(body: Record<string, unknown>) {
  return {
    quantity_received: body.initialQuantity,
    quantity_remaining: body.remainingQuantity ?? body.initialQuantity,
    unit_cost: body.unitPrice,
    expiry_date: body.expiryDate ?? null,
    received_at: body.purchasedAt,
    supplier: body.supplier ?? null,
    storage_location: body.storageLocation ?? null,
    note: body.note ?? null,
  };
}

async function addBatch(supabase: SupabaseClient, productId: string, request: Request) {
  const body = await request.json();
  const storeId = requireStoreFromBody(body);

  const { error } = await supabase
    .from('batches')
    .insert({ product_id: productId, store_id: storeId, ...batchColumns(body) });
  if (error) throw error;

  return ok(await productJson(supabase, productId, storeId), 201);
}

async function updateBatch(
  supabase: SupabaseClient,
  productId: string,
  batchId: string,
  request: Request,
) {
  const body = await request.json();
  const storeId = requireStoreFromBody(body);

  const { error } = await supabase
    .from('batches')
    .update(batchColumns(body))
    .eq('id', batchId)
    .eq('product_id', productId);
  if (error) throw error;

  return ok(await productJson(supabase, productId, storeId));
}

async function archiveBatch(
  supabase: SupabaseClient,
  productId: string,
  batchId: string,
  url: URL,
) {
  const storeId = requireStoreFromQuery(url);

  const { error } = await supabase
    .from('batches')
    .update({ deleted_at: new Date().toISOString() })
    .eq('id', batchId)
    .eq('product_id', productId);
  if (error) throw error;

  return ok(await productJson(supabase, productId, storeId));
}

async function consume(supabase: SupabaseClient, productId: string, request: Request) {
  const body = await request.json();
  const storeId = requireStoreFromBody(body);

  const { data, error } = await supabase.rpc('apply_consumption', {
    p_product_id: productId,
    p_store_id: storeId,
    p_allocations: body.allocations,
  });
  if (error) throw error;
  return ok(data);
}
