import { clientFor } from '../_shared/client.ts';
import { fail, ok } from '../_shared/envelope.ts';

const CONTENT_TYPES: Record<string, string> = {
  jpg: 'image/jpeg',
  jpeg: 'image/jpeg',
  png: 'image/png',
  webp: 'image/webp',
};

const MAX_BYTES = 5 * 1024 * 1024;

Deno.serve(async (request: Request) => {
  if (request.method !== 'POST') return fail('NOT_FOUND', 'No such route.', 404);

  const supabase = clientFor(request);
  if (!supabase) return fail('UNAUTHORIZED', 'A bearer token is required.', 401);

  const { data: session } = await supabase.auth.getUser();
  if (!session.user) return fail('UNAUTHORIZED', 'A bearer token is required.', 401);

  let form: FormData;
  try {
    form = await request.formData();
  } catch {
    return fail('BAD_REQUEST', 'A multipart body is required.', 400);
  }

  const file = form.get('file');
  if (!(file instanceof File)) return fail('BAD_REQUEST', 'A file part is required.', 400);
  if (file.size > MAX_BYTES) return fail('BAD_REQUEST', 'That image is larger than 5 MB.', 400);

  const extension = (file.name.split('.').pop() ?? '').toLowerCase();
  const contentType = CONTENT_TYPES[extension];
  if (!contentType) return fail('BAD_REQUEST', 'That image format is not supported.', 400);

  // The uid is the second path segment because that is the segment the storage
  // policy compares against auth.uid().
  const path = `products/${session.user.id}/${Date.now()}.${extension}`;
  const { error } = await supabase.storage
    .from('product-images')
    .upload(path, file, { contentType, upsert: true });
  if (error) return fail('SERVER_ERROR', error.message, 500);

  const { data } = supabase.storage.from('product-images').getPublicUrl(path);
  return ok({ url: data.publicUrl }, 201);
});
