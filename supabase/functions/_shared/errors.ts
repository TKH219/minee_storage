import { fail } from './envelope.ts';

export type PostgresError = { code?: string; message?: string };

// The P0001-P0003 codes are the ones apply_consumption and batches_parents_agree
// raise; the rest are Postgres' own.
const BY_ERRCODE: Record<string, [string, number]> = {
  P0001: ['CONFLICT', 409],
  P0002: ['NOT_FOUND', 404],
  P0003: ['INSUFFICIENT_STOCK', 409],
  '22023': ['BAD_REQUEST', 400],
  '22P02': ['BAD_REQUEST', 400],
  '23502': ['BAD_REQUEST', 400],
  '23503': ['BAD_REQUEST', 400],
  '23505': ['BARCODE_TAKEN', 409],
  '23514': ['BAD_REQUEST', 400],
  '42501': ['FORBIDDEN', 403],
};

export function failFromPostgres(error: PostgresError): Response {
  const [code, status] = BY_ERRCODE[error.code ?? ''] ?? ['SERVER_ERROR', 500];
  return fail(code, error.message ?? 'The request could not be completed.', status);
}

export function badRequest(message: string): PostgresError {
  return { code: '22023', message };
}
