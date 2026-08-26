import { fail } from './envelope.ts';

export type PostgresError = { code?: string; message?: string };

// The P0001-P0010 codes are the ones apply_consumption, batches_parents_agree,
// amend_batch and the three transaction RPCs raise; the rest are Postgres' own.
const BY_ERRCODE: Record<string, [string, number]> = {
  P0001: ['CONFLICT', 409],
  P0002: ['NOT_FOUND', 404],
  P0003: ['INSUFFICIENT_STOCK', 409],
  P0004: ['QUANTITY_BELOW_DRAWN', 409],
  P0005: ['OCCURRED_BEFORE_ARRIVAL', 409],
  P0006: ['FEE_NOT_ALLOWED', 400],
  P0007: ['REVERSAL_BELOW_ZERO', 409],
  P0008: ['REVERSAL_ABOVE_RECEIVED', 409],
  P0009: ['BATCH_ALREADY_DRAWN', 409],
  P0010: ['STALE_TRANSACTION', 409],
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
