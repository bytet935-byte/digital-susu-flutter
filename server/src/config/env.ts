import dotenv from 'dotenv';

dotenv.config();

/**
 * Centralised environment configuration (spec §26: secrets live in the
 * environment, never in source code). Fails fast in production when required
 * values are missing.
 */
function required(name: string, fallback?: string): string {
  const value = process.env[name] ?? fallback;
  if (value === undefined) {
    if (process.env.NODE_ENV === 'production') {
      throw new Error(`Missing required environment variable: ${name}`);
    }
    throw new Error(
      `Missing required environment variable: ${name} (see server/.env.example)`,
    );
  }
  return value;
}

export const env = {
  nodeEnv: process.env.NODE_ENV ?? 'development',
  port: Number(process.env.PORT ?? 8080),
  isProduction: process.env.NODE_ENV === 'production',

  /** PostgreSQL connection string; unset → in-memory mode. */
  databaseUrl: process.env.DATABASE_URL,

  jwtAccessSecret: required('JWT_ACCESS_SECRET', 'dev-access-secret'),
  jwtRefreshSecret: required('JWT_REFRESH_SECRET', 'dev-refresh-secret'),
  jwtAccessExpiresIn: process.env.JWT_ACCESS_EXPIRES_IN ?? '15m',
  jwtRefreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '30d',

  bcryptRounds: Number(process.env.BCRYPT_ROUNDS ?? 10),

  corsOrigins: (process.env.CORS_ORIGINS ?? '')
    .split(',')
    .map((origin) => origin.trim())
    .filter(Boolean),

  rateLimitWindowMs: Number(process.env.RATE_LIMIT_WINDOW_MS ?? 60_000),
  rateLimitMax: Number(process.env.RATE_LIMIT_MAX ?? 120),
} as const;
