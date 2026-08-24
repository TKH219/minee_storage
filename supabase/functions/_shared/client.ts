import { createClient, SupabaseClient } from 'jsr:@supabase/supabase-js@2';

// The caller's own Authorization header is forwarded to PostgREST, which is
// what keeps row level security the enforcement point. The service-role key is
// deliberately never read here.
export function clientFor(request: Request): SupabaseClient | null {
  const authorization = request.headers.get('Authorization');
  if (!authorization?.startsWith('Bearer ')) return null;

  return createClient(
    Deno.env.get('SUPABASE_URL')!,
    Deno.env.get('SUPABASE_ANON_KEY')!,
    {
      global: { headers: { Authorization: authorization } },
      auth: { persistSession: false, autoRefreshToken: false },
    },
  );
}
