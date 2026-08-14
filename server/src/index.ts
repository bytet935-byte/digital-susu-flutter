import { createApp } from './app';
import { env } from './config/env';

const { app } = createApp();

app.listen(env.port, () => {
  // eslint-disable-next-line no-console
  console.log(
    `[digital-susu] API listening on :${env.port} (mode: ${
      env.databaseUrl ? 'postgres' : 'memory'
    })`,
  );
});
