import { NextFunction, Request, Response } from 'express';
import { ZodSchema } from 'zod';

import { ApiError } from '../utils/api-error';

/**
 * Validation at the API boundary (spec §23, §27): parses req.body against a
 * zod schema and replaces it with the validated (typed) value.
 */
export function validateBody(schema: ZodSchema) {
  return (req: Request, _res: Response, next: NextFunction): void => {
    const parsed = schema.safeParse(req.body);
    if (!parsed.success) {
      throw ApiError.badRequest(
        'Please check your input and try again.',
        parsed.error.issues.map((issue) => ({
          path: issue.path.join('.'),
          message: issue.message,
        })),
      );
    }
    req.body = parsed.data;
    next();
  };
}
