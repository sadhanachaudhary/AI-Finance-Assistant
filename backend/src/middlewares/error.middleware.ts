import { Request, Response, NextFunction } from 'express';
import { formatUserFriendlyError } from '../utils/app-error';

/**
 * Hardened Global Error Handling Middleware
 * - Intercepts technical exceptions, validation errors, and database failures
 * - Returns clean, polite, user-friendly error responses with actionable tips
 * - Never leaks raw database schemas or secrets
 */
export const errorMiddleware = (
  err: any,
  req: Request,
  res: Response,
  next: NextFunction
) => {
  // Safe server-side error logging
  console.error(`[Error] [${req.method}] ${req.originalUrl}:`, err.message || err);

  const formatted = formatUserFriendlyError(err);

  res.status(formatted.statusCode).json({
    status: formatted.statusCode >= 500 ? 'error' : 'fail',
    message: formatted.message,
    ...(formatted.tip ? { tip: formatted.tip } : {}),
    ...(process.env.NODE_ENV === 'development' && formatted.statusCode === 500
      ? { debugStack: err.stack }
      : {}),
  });
};
