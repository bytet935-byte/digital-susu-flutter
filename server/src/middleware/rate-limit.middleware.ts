import rateLimit from 'express-rate-limit';

import { env } from '../config/env';

/**
 * Basic per-IP rate limiting (spec §12, §27). Tightened per-endpoint (OTP,
 * login) as the auth feature evolves.
 */
export const globalRateLimit = rateLimit({
  windowMs: env.rateLimitWindowMs,
  limit: env.rateLimitMax,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: { code: 'RATE_LIMITED', message: 'Too many requests. Please wait a moment.' },
  },
});

/** Stricter limiter for sensitive endpoints (login, OTP, password reset). */
export const authRateLimit = rateLimit({
  windowMs: 15 * 60 * 1000,
  limit: 20,
  standardHeaders: true,
  legacyHeaders: false,
  message: {
    error: { code: 'RATE_LIMITED', message: 'Too many attempts. Please wait before trying again.' },
  },
});
