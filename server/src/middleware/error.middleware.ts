import { NextFunction, Request, Response } from 'express';

import { env } from '../config/env';
import { ApiError } from '../utils/api-error';

/**
 * Centralised error handling (spec §12, §23): every error — ApiError, zod
 * errors, unexpected exceptions — becomes a consistent JSON envelope. Raw
 * technical details are logged server-side but never leaked to clients.
 */
export function errorMiddleware(
  error: unknown,
  _req: Request,
  res: Response,
  _next: NextFunction,
): void {
  if (error instanceof ApiError) {
    res.status(error.statusCode).json({
      error: {
        code: error.code,
        message: error.message,
        ...(error.details !== undefined ? { details: error.details } : {}),
      },
    });
    return;
  }

  // zod validation errors thrown outside the validation middleware.
  if (isZodError(error)) {
    res.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Invalid request body',
        details: error.issues,
      },
    });
    return;
  }

  // Unexpected error — log and return a friendly 500 (never the stack).
  console.error('[api] unhandled error', error);
  res.status(500).json({
    error: {
      code: 'INTERNAL_ERROR',
      message: env.isProduction
        ? 'Something went wrong. Please try again.'
        : `Internal error: ${String(error)}`,
    },
  });
}

function isZodError(value: unknown): value is { issues: unknown[] } {
  return (
    typeof value === 'object' &&
    value !== null &&
    'issues' in value &&
    Array.isArray((value as { issues: unknown[] }).issues)
  );
}

/** 404 handler for unknown routes. */
export function notFoundHandler(_req: Request, res: Response): void {
  res.status(404).json({
    error: { code: 'NOT_FOUND', message: 'Route not found' },
  });
}
