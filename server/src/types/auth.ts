import { Request } from 'express';

import { ApiError } from '../utils/api-error';

/**
 * Authenticated request — populated by the auth middleware from a verified
 * access token (spec §10, §27: the backend never trusts client claims).
 */
export interface AuthenticatedRequest extends Request {
  auth?: {
    userId: string;
    sessionId: string;
  };
}

/** Extracts the authenticated user id or throws 401. */
export function requireAuth(req: AuthenticatedRequest): {
  userId: string;
  sessionId: string;
} {
  if (!req.auth) {
    throw ApiError.unauthorized();
  }
  return req.auth;
}

declare global {
  // eslint-disable-next-line @typescript-eslint/no-namespace
  namespace Express {
    interface Request {
      auth?: { userId: string; sessionId: string };
    }
  }
}
