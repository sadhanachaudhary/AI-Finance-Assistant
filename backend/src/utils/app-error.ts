import { ZodError } from 'zod';

/**
 * Standard Application Error with HTTP status and user-facing clarity.
 */
export class AppError extends Error {
  public readonly statusCode: number;
  public readonly isOperational: boolean;
  public readonly userMessage: string;

  constructor(message: string, statusCode = 400, userMessage?: string) {
    super(message);
    this.statusCode = statusCode;
    this.isOperational = true;
    this.userMessage = userMessage || message;
    Error.captureStackTrace(this, this.constructor);
  }
}

/**
 * Converts technical exceptions, validation schemas, or database issues into
 * clear, polite, human-centric error messages and recovery tips.
 */
export const formatUserFriendlyError = (err: any): { statusCode: number; message: string; tip?: string } => {
  // 1. Zod Validation Error Handling
  if (err instanceof ZodError) {
    const issue = err.issues[0];
    const field = issue.path.join('.').replace('body.', '');
    let friendly = issue.message;

    if (issue.code === 'invalid_type') {
      friendly = `Please enter a valid ${field || 'value'}.`;
    } else if (field === 'email') {
      friendly = 'Please provide a valid email address (e.g. name@example.com).';
    } else if (field === 'password' && issue.message.includes('6')) {
      friendly = 'Your password must be at least 6 characters long.';
    } else if (field === 'amount') {
      friendly = 'Please enter a valid expense amount greater than 0.';
    }

    return {
      statusCode: 422,
      message: friendly,
      tip: 'Check highlighted inputs and try again.',
    };
  }

  // 2. JWT & Authentication Errors
  if (err.name === 'TokenExpiredError' || err.message?.includes('jwt expired')) {
    return {
      statusCode: 401,
      message: 'Your login session has expired.',
      tip: 'Please sign in again to continue managing your finances securely.',
    };
  }

  if (err.name === 'JsonWebTokenError' || err.message?.includes('invalid token')) {
    return {
      statusCode: 401,
      message: 'Authentication credentials could not be verified.',
      tip: 'Please log in with your credentials.',
    };
  }

  // 3. Prisma Database Errors
  if (err.code && typeof err.code === 'string' && err.code.startsWith('P')) {
    switch (err.code) {
      case 'P2002':
        return {
          statusCode: 409,
          message: 'An account or record with this information already exists.',
          tip: 'Try signing in with your email or use a different name.',
        };
      case 'P2025':
        return {
          statusCode: 404,
          message: 'The requested item or record could not be found.',
          tip: 'It may have been recently deleted or moved.',
        };
      case 'P2003':
        return {
          statusCode: 400,
          message: 'This action depends on a related record that does not exist.',
          tip: 'Make sure associated categories or bills are valid.',
        };
      default:
        return {
          statusCode: 503,
          message: 'Database connection temporarily busy.',
          tip: 'Your data is safe. Please retry in a few moments.',
        };
    }
  }

  // 4. Custom AppError instances
  if (err instanceof AppError) {
    return {
      statusCode: err.statusCode,
      message: err.userMessage,
    };
  }

  // 5. Network & Timeout Errors
  if (err.code === 'ECONNREFUSED' || err.code === 'ETIMEDOUT') {
    return {
      statusCode: 503,
      message: 'Could not reach server service.',
      tip: 'Please check your internet connection and try again.',
    };
  }

  // 6. Generic Fallback
  const rawMsg = err.message || 'An unexpected error occurred.';
  const safeMessage = typeof rawMsg === 'string' && !rawMsg.includes('Prisma') && !rawMsg.includes('SELECT')
    ? rawMsg
    : 'Something went wrong while processing your request.';

  return {
    statusCode: err.statusCode || 500,
    message: safeMessage,
    tip: 'If this continues, please restart the application.',
  };
};
