import { Request, Response, NextFunction } from 'express';

/**
 * Hardened Global Error Handling Middleware
 * - Intercepts Prisma & database errors to prevent leaking connection strings, table schemas, or raw SQL
 * - Returns clean, sanitized, standard JSON responses to API consumers
 */
export const errorMiddleware = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // Log internal error safely for debugging on server side only
  console.error(`[Error] [${req.method}] ${req.originalUrl}:`, err.message || err);

  let status = err.statusCode || 500;
  let message = err.message || 'Internal Server Error';

  // Sanitize Prisma & Database specific errors
  if (err.code && typeof err.code === 'string' && err.code.startsWith('P')) {
    status = 400;
    switch (err.code) {
      case 'P2002':
        // Unique constraint violation (e.g. duplicate email)
        const target = err.meta?.target ? ` (${Array.isArray(err.meta.target) ? err.meta.target.join(', ') : err.meta.target})` : '';
        message = `A record with this value already exists${target}.`;
        break;
      case 'P2025':
        // Record not found
        status = 404;
        message = 'The requested record was not found.';
        break;
      case 'P2003':
        // Foreign key constraint failure
        message = 'Referenced related record does not exist or is locked.';
        break;
      default:
        message = 'Database operation could not be completed safely.';
        break;
    }
  }

  // Prevent leaking internal server tokens or database URLs in error messages
  if (typeof message === 'string') {
    message = message.replace(/postgresql:\/\/[^@]+@/gi, 'postgresql://***:***@');
  }

  res.status(status).json({
    status: status >= 500 ? 'error' : 'fail',
    message,
    ...(process.env.NODE_ENV === 'development' && status < 500 ? { details: err.meta } : {}),
  });
};
