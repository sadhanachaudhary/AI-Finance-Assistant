import { AppError, formatUserFriendlyError } from '../utils/app-error';
import { z } from 'zod';

describe('AppError & Error Formatter Unit Tests', () => {
  test('AppError sets operational flag and custom statusCode', () => {
    const error = new AppError('Resource not found', 404, 'We could not find the requested expense.');
    expect(error.statusCode).toBe(404);
    expect(error.isOperational).toBe(true);
    expect(error.userMessage).toBe('We could not find the requested expense.');
  });

  test('formatUserFriendlyError formats Zod validation errors nicely', () => {
    const schema = z.object({
      email: z.string().email(),
      amount: z.number().positive(),
    });

    const parseResult = schema.safeParse({ email: 'invalid-email', amount: -50 });
    if (!parseResult.success) {
      const formatted = formatUserFriendlyError(parseResult.error);
      expect(formatted.statusCode).toBe(422);
      expect(formatted.tip).toBeDefined();
      expect(formatted.message).toContain('valid email');
    }
  });

  test('formatUserFriendlyError maps JWT expiration cleanly', () => {
    const jwtErr = new Error('jwt expired');
    jwtErr.name = 'TokenExpiredError';

    const formatted = formatUserFriendlyError(jwtErr);
    expect(formatted.statusCode).toBe(401);
    expect(formatted.message).toBe('Your login session has expired.');
    expect(formatted.tip).toContain('sign in again');
  });

  test('formatUserFriendlyError handles Prisma unique constraint P2002', () => {
    const prismaErr: any = new Error('Unique constraint failed on the fields: (`email`)');
    prismaErr.code = 'P2002';

    const formatted = formatUserFriendlyError(prismaErr);
    expect(formatted.statusCode).toBe(409);
    expect(formatted.message).toContain('already exists');
  });

  test('formatUserFriendlyError handles database disconnection gracefully', () => {
    const connErr: any = new Error('Connection refused');
    connErr.code = 'ECONNREFUSED';

    const formatted = formatUserFriendlyError(connErr);
    expect(formatted.statusCode).toBe(503);
    expect(formatted.message).toBe('Could not reach server service.');
  });
});
