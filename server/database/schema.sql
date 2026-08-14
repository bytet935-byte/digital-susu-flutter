-- ============================================================================
-- DIGITAL SUSU V2 — PostgreSQL schema (spec §24, §25)
--
-- Domains: IDENTITY · GROUPS · FINANCIALS · SAVINGS · COMMUNICATION ·
-- SECURITY · GOVERNANCE · REPORTING · ADMINISTRATION · INTEGRATIONS
--
-- Conventions:
--   * UUID primary keys (gen_random_uuid via pgcrypto)
--   * timestamptz columns; created_at/updated_at on mutable tables
--   * enums instead of magic strings; CHECK constraints for invariants
--   * append-only financial records (transactions, ledger_entries, audit_logs)
--   * indexes on foreign keys and hot query paths
-- ============================================================================

CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------

CREATE TYPE user_role AS ENUM ('MEMBER','GROUP_OWNER','ADMIN','TREASURER','MODERATOR','SYSTEM_ADMIN');
CREATE TYPE group_type AS ENUM ('ROTATIONAL_SUSU','SAVINGS_GOAL','JOINT_BUSINESS');
CREATE TYPE group_status AS ENUM ('ACTIVE','UPCOMING','COMPLETED','PENDING','PAUSED');
CREATE TYPE txn_type AS ENUM (
  'CONTRIBUTION','PAYOUT','DEPOSIT','WITHDRAWAL','TRANSFER','FEE','PENALTY',
  'EXPENSE','BUSINESS_INCOME','BUSINESS_DISTRIBUTION','REFUND','ADJUSTMENT'
);
CREATE TYPE txn_status AS ENUM ('SUCCESSFUL','PENDING','FAILED','REVERSED');
CREATE TYPE kyc_status AS ENUM ('NOT_STARTED','PENDING','VERIFIED','REJECTED','EXPIRED');
CREATE TYPE payout_status AS ENUM ('UPCOMING','PROCESSING','COMPLETED','FAILED');
CREATE TYPE membership_status AS ENUM ('ACTIVE','PENDING','REMOVED');

-- ---------------------------------------------------------------------------
-- IDENTITY
-- ---------------------------------------------------------------------------

CREATE TABLE users (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  full_name     TEXT NOT NULL CHECK (char_length(full_name) BETWEEN 2 AND 60),
  phone         TEXT NOT NULL UNIQUE,
  email         TEXT UNIQUE,
  password_hash TEXT NOT NULL,
  kyc_status    kyc_status NOT NULL DEFAULT 'NOT_STARTED',
  verified      BOOLEAN NOT NULL DEFAULT FALSE,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_users_email ON users (lower(email));

CREATE TABLE sessions (
  id                 UUID PRIMARY KEY,
  user_id            UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  refresh_token_hash TEXT NOT NULL,
  expires_at         TIMESTAMPTZ NOT NULL,
  revoked_at         TIMESTAMPTZ,
  created_at         TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_sessions_user ON sessions (user_id);
CREATE INDEX idx_sessions_active ON sessions (user_id) WHERE revoked_at IS NULL;

CREATE TABLE devices (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  device_name   TEXT NOT NULL,
  platform      TEXT,
  push_token    TEXT,
  last_seen_at  TIMESTAMPTZ,
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, device_name)
);

CREATE TABLE otp_codes (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  purpose    TEXT NOT NULL CHECK (purpose IN ('VERIFY_PHONE','PASSWORD_RESET','LOGIN')),
  code_hash  TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE password_resets (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code_hash  TEXT NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  used       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE kyc_documents (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  document_type TEXT NOT NULL,
  status       kyc_status NOT NULL DEFAULT 'PENDING',
  file_url     TEXT NOT NULL,
  reviewed_by  UUID REFERENCES users(id),
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ---------------------------------------------------------------------------
-- GROUPS & GOVERNANCE
-- ---------------------------------------------------------------------------

CREATE TABLE susu_groups (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_id    UUID NOT NULL REFERENCES users(id),
  name        TEXT NOT NULL CHECK (char_length(name) BETWEEN 2 AND 60),
  type        group_type NOT NULL,
  description TEXT,
  currency    CHAR(3) NOT NULL DEFAULT 'GHS',
  status      group_status NOT NULL DEFAULT 'ACTIVE',
  rules       JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_groups_owner ON susu_groups (owner_id);

CREATE TABLE group_members (
  group_id    UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  role        user_role NOT NULL DEFAULT 'MEMBER',
  status      membership_status NOT NULL DEFAULT 'ACTIVE',
  permissions TEXT[] NOT NULL DEFAULT '{}',
  joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (group_id, user_id)
);

CREATE INDEX idx_members_user ON group_members (user_id);

CREATE TABLE group_invitations (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id   UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  invited_by UUID NOT NULL REFERENCES users(id),
  phone      TEXT,
  email      TEXT,
  token      TEXT NOT NULL UNIQUE,
  status     membership_status NOT NULL DEFAULT 'PENDING',
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  accepted_at TIMESTAMPTZ
);

CREATE TABLE join_requests (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id   UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  status     membership_status NOT NULL DEFAULT 'PENDING',
  decided_by UUID REFERENCES users(id),
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (group_id, user_id)
);

-- ---------------------------------------------------------------------------
-- FINANCIALS (spec §7, §8: wallets are structurally separated)
-- ---------------------------------------------------------------------------

CREATE TABLE wallets (
  id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  owner_user_id UUID REFERENCES users(id) ON DELETE CASCADE,
  group_id      UUID REFERENCES susu_groups(id) ON DELETE CASCADE,
  balance_minor BIGINT NOT NULL DEFAULT 0 CHECK (balance_minor >= 0),
  currency      CHAR(3) NOT NULL DEFAULT 'GHS',
  created_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
  -- A wallet is EITHER personal OR group-owned — never both (spec §7).
  CHECK (
    (owner_user_id IS NOT NULL AND group_id IS NULL) OR
    (owner_user_id IS NULL AND group_id IS NOT NULL)
  )
);

CREATE UNIQUE INDEX idx_wallets_personal ON wallets (owner_user_id) WHERE group_id IS NULL;
CREATE UNIQUE INDEX idx_wallets_group ON wallets (group_id) WHERE owner_user_id IS NULL;

-- Append-only financial record (spec §8): never updated in place for value
-- changes; corrections create ADJUSTMENT/REVERSAL rows.
CREATE TABLE transactions (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id          UUID NOT NULL REFERENCES users(id),
  group_id         UUID REFERENCES susu_groups(id),
  wallet_id        UUID NOT NULL REFERENCES wallets(id),
  amount_minor     BIGINT NOT NULL CHECK (amount_minor <> 0),
  currency         CHAR(3) NOT NULL DEFAULT 'GHS',
  type             txn_type NOT NULL,
  status           txn_status NOT NULL DEFAULT 'PENDING',
  reference        TEXT NOT NULL UNIQUE,
  idempotency_key  TEXT UNIQUE,
  payment_method   TEXT,
  external_ref     TEXT,
  metadata         JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  created_by       UUID NOT NULL REFERENCES users(id),
  approved_by      UUID REFERENCES users(id)
);

CREATE INDEX idx_transactions_user ON transactions (user_id, created_at DESC);
CREATE INDEX idx_transactions_group ON transactions (group_id, created_at DESC);
CREATE INDEX idx_transactions_wallet ON transactions (wallet_id, created_at DESC);

-- Double-entry ledger (spec §24): every wallet mutation has matching entries.
CREATE TABLE ledger_accounts (
  id        UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  name      TEXT NOT NULL UNIQUE,
  account_type TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE ledger_entries (
  id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  transaction_id   UUID NOT NULL REFERENCES transactions(id),
  account_id       UUID NOT NULL REFERENCES ledger_accounts(id),
  debit_minor      BIGINT NOT NULL DEFAULT 0 CHECK (debit_minor >= 0),
  credit_minor     BIGINT NOT NULL DEFAULT 0 CHECK (credit_minor >= 0),
  created_at       TIMESTAMPTZ NOT NULL DEFAULT now(),
  CHECK (debit_minor > 0 OR credit_minor > 0)
);

CREATE TABLE contribution_schedules (
  id             UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id       UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  amount_minor   BIGINT NOT NULL CHECK (amount_minor > 0),
  frequency      TEXT NOT NULL,  -- DAILY | WEEKLY | BIWEEKLY | MONTHLY
  start_date     DATE NOT NULL,
  end_date       DATE,
  active         BOOLEAN NOT NULL DEFAULT TRUE,
  created_at     TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE payout_cycles (
  id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id        UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  cycle_number    INT NOT NULL,
  period_start    DATE NOT NULL,
  period_end      DATE,
  payout_amount_minor BIGINT NOT NULL CHECK (payout_amount_minor > 0),
  recipient_user_id UUID NOT NULL REFERENCES users(id),
  status          payout_status NOT NULL DEFAULT 'UPCOMING',
  paid_at         TIMESTAMPTZ,
  payout_txn_id   UUID REFERENCES transactions(id),
  created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (group_id, cycle_number)
);

-- ---------------------------------------------------------------------------
-- COMMUNICATION
-- ---------------------------------------------------------------------------

CREATE TABLE group_messages (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id   UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  sender_id  UUID NOT NULL REFERENCES users(id),
  body       TEXT NOT NULL,
  kind       TEXT NOT NULL DEFAULT 'MESSAGE', -- MESSAGE | ANNOUNCEMENT
  pinned     BOOLEAN NOT NULL DEFAULT FALSE,
  edited_at  TIMESTAMPTZ,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_messages_group ON group_messages (group_id, created_at);

CREATE TABLE message_reports (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  message_id  UUID NOT NULL REFERENCES group_messages(id) ON DELETE CASCADE,
  reported_by UUID NOT NULL REFERENCES users(id),
  reason      TEXT NOT NULL,
  resolved    BOOLEAN NOT NULL DEFAULT FALSE,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE notifications (
  id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id    UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  title      TEXT NOT NULL,
  body       TEXT NOT NULL,
  category   TEXT NOT NULL,
  read       BOOLEAN NOT NULL DEFAULT FALSE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_notifications_user ON notifications (user_id, read, created_at DESC);

-- ---------------------------------------------------------------------------
-- GOVERNANCE (spec §20, §26)
-- ---------------------------------------------------------------------------

CREATE TABLE proposals (
  id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  group_id     UUID NOT NULL REFERENCES susu_groups(id) ON DELETE CASCADE,
  created_by   UUID NOT NULL REFERENCES users(id),
  title        TEXT NOT NULL,
  description  TEXT,
  options      JSONB NOT NULL,
  voting_ends  TIMESTAMPTZ NOT NULL,
  status       TEXT NOT NULL DEFAULT 'OPEN', -- OPEN | APPROVED | REJECTED | EXPIRED
  result       JSONB,
  created_at   TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE proposal_votes (
  proposal_id UUID NOT NULL REFERENCES proposals(id) ON DELETE CASCADE,
  user_id     UUID NOT NULL REFERENCES users(id),
  option      TEXT NOT NULL,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
  PRIMARY KEY (proposal_id, user_id)  -- one vote per user per proposal
);

-- ---------------------------------------------------------------------------
-- AUDIT (spec §26: append-only, not casually editable)
-- ---------------------------------------------------------------------------

CREATE TABLE audit_logs (
  id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id     UUID REFERENCES users(id),
  action      TEXT NOT NULL,
  entity_type TEXT,
  entity_id   TEXT,
  metadata    JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX idx_audit_entity ON audit_logs (entity_type, entity_id, created_at DESC);
CREATE INDEX idx_audit_user ON audit_logs (user_id, created_at DESC);

-- ---------------------------------------------------------------------------
-- updated_at trigger
-- ---------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS trigger AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_groups_updated BEFORE UPDATE ON susu_groups
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
CREATE TRIGGER trg_wallets_updated BEFORE UPDATE ON wallets
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();
