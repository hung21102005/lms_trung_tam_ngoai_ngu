import { Prisma } from '@prisma/client';
import { describe, expect, it } from 'vitest';
import { isRetryableTransactionConflict } from './prisma-transaction.js';

describe('isRetryableTransactionConflict', () => {
  it('recognizes Prisma serialization errors and PostgreSQL deadlocks', () => {
    expect(
      isRetryableTransactionConflict(
        new Prisma.PrismaClientKnownRequestError('retry', {
          code: 'P2034',
          clientVersion: 'test',
        }),
      ),
    ).toBe(true);
    expect(
      isRetryableTransactionConflict(
        new Prisma.PrismaClientUnknownRequestError(
          'PostgresError { code: "40P01", message: "deadlock detected" }',
          { clientVersion: 'test' },
        ),
      ),
    ).toBe(true);
    expect(
      isRetryableTransactionConflict(
        new Prisma.PrismaClientUnknownRequestError(
          'PostgresError { code: "40001", message: "serialization failure" }',
          { clientVersion: 'test' },
        ),
      ),
    ).toBe(true);
  });

  it('does not retry arbitrary PostgreSQL or validation errors', () => {
    expect(
      isRetryableTransactionConflict(
        new Prisma.PrismaClientUnknownRequestError(
          'PostgresError { code: "P0001", message: "invoice failed" }',
          { clientVersion: 'test' },
        ),
      ),
    ).toBe(false);
    expect(isRetryableTransactionConflict(new Error('40P01'))).toBe(false);
  });
});
