export function json(body: unknown, status: number): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { 'Content-Type': 'application/json' },
  });
}

export function ok<T>(data: T, status = 200): Response {
  return json({ code: 'OK', message: 'Success', data }, status);
}

export function fail(code: string, message: string, status: number): Response {
  return json({ code, message }, status);
}
