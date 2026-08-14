import { NextFunction, Response } from 'express';
import jwt from 'jsonwebtoken';

import { env } from '../config/env';
import { AuthenticatedRequest } from '../types/auth';
import { ApiError } from '../utils/api-error';

export interface AccessTokenPayload {
  sub: string;
  sid: string;
  type: 'access';
}

/**
 * Verifies the Bearer access token and attaches the authenticated user to the
 * request (spec §10, §27). Token expiry is signalled as a distinct 401 code so
 * clients can refresh and retry once.
 */
export function authMiddleware(
  req: AuthenticatedRequest,
  _res: Response,
  next: NextFunction,
): void {
  const header = req.headers.authorization;
  if (!header?.startsWith('Bearer ')) {
    throw ApiError.unauthorized('Missing access token');
  }
  const token = header.slice('Bearer '.length).trim();
  try {
    const payload = jwt.verify(token, env.jwtAccessSecret) as AccessTokenPayload;
    if (payload.type !== 'access' || !payload.sub || !payload.sid) {
      throw new Error('unexpected payload');
    }
    req.auth = { userId: payload.sub, sessionId: payload.sid };
    next();
  } catch {
    throw new ApiError(401, 'TOKEN_EXPIRED', 'Your session has expired. Please log in again.');
  }
}
