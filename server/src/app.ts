import cors from 'cors';
import express, { Express } from 'express';
import helmet from 'helmet';

import { buildContainer, Container } from './container';
import { env } from './config/env';
import { errorMiddleware, notFoundHandler } from './middleware/error.middleware';
import { globalRateLimit } from './middleware/rate-limit.middleware';
import { buildRouter } from './routes';

/**
 * Express application factory (spec §23). Exported so tests can boot the app
 * with supertest without listening on a port.
 */
export function createApp(): { app: Express; container: Container } {
  const container = buildContainer();
  const app = express();

  app.disable('x-powered-by');
  app.use(helmet());
  app.use(
    cors({
      origin: env.corsOrigins.length > 0 ? env.corsOrigins : true,
      credentials: true,
    }),
  );
  app.use(express.json({ limit: '256kb' }));
  app.use(globalRateLimit);
  app.use('/api/v1', buildRouter(container));

  app.use(notFoundHandler);
  app.use(errorMiddleware);

  return { app, container };
}
