# Digital Susu V2 — API

Ghana-first savings, susu, wallet and group-finance backend.
**Node.js + TypeScript + Express + PostgreSQL** (spec §23).

## Architecture (spec §23)

```
Routes → Controllers → Services → Repositories → PostgreSQL
```

- **Routes** define HTTP surface; **controllers** translate HTTP ↔ use cases;
  **services** hold business rules (auth, wallets, transactions, groups);
  **repositories** own persistence (PostgreSQL or in-memory).
- **Validation** at the boundary (zod schemas in `src/validators`).
- **Consistent error handling**: services throw `ApiError`; the error
  middleware maps everything to `{ error: { code, message } }` — no stack
  traces leak to clients (spec §12/§26 spirit).

## Quick start

```sh
cd server
npm install

# Development — in-memory mode (no database required)
npm run dev

# Development — PostgreSQL mode
cp .env.example .env      # set DATABASE_URL + JWT secrets
psql "$DATABASE_URL" -f database/schema.sql
npm run dev

# Verification
npm run typecheck
npm test
npm run build && npm start
```

## In-memory vs PostgreSQL mode

When `DATABASE_URL` is set, repositories use PostgreSQL (`src/repositories/pg.repos.ts`).
Without it, the API runs on in-memory repositories (dev/demo/tests) so the
whole stack is testable anywhere (spec §30: UI/API connect later without
rebuilding).

## Security engineering (spec §26)

- No secrets in source. `.env.example` documents required variables only.
- Passwords hashed with bcrypt (10 rounds default).
- Short-lived access tokens (JWT) + rotating refresh tokens stored in
  `sessions`.
- Rate limiting, helmet, CORS allow-list, validation at every boundary.
- Never trust client-supplied ids for authorization — services check the
  authenticated user's ownership/permissions.

## Database

`database/schema.sql` — full domain model: identity, groups, financials
(wallets/ledger/contributions/payouts), communication, governance, security,
reporting, admin. UUID PKs, enums, FKs, indexes, timestamps, audit columns.

## Testing (spec §29)

- Unit: auth service (register/login/refresh/logout/verify), wallet service
  (top-up/withdraw/balance, no negative balances), transaction service
  (idempotency, duplicate prevention).
- API: supertest against the Express app (register → login → wallet flows).
