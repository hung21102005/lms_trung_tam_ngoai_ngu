import { Prisma } from '@prisma/client';

/** PostgreSQL SQLSTATEs may be wrapped as unknown errors by the Prisma adapter. */
export function isRetryableTransactionConflict(error: unknown): boolean {
  if (error instanceof Prisma.PrismaClientKnownRequestError) {
    return error.code === 'P2034';
  }
  return (
    error instanceof Prisma.PrismaClientUnknownRequestError &&
    /\b(?:40P01|40001)\b/.test(error.message)
  );
}
