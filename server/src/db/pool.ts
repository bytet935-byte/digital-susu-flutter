import { Pool } from 'pg';

import { env } from '../config/env';

/**
 * PostgreSQL pool. Only created when DATABASE_URL is set — otherwise the API
 * runs on in-memory repositories (see repositories/README).
 */
export const pool = env.databaseUrl ? new Pool({ connectionString: env.databaseUrl }) : null;

export const isPgEnabled = pool !== null;
