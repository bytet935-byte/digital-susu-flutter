import { Pool, QueryResultRow } from 'pg';

import {
  AuditLog,
  GroupMember,
  Notification,
  Session,
  SusuGroup,
  Transaction,
  User,
  Wallet,
} from '../models';
import {
  AuditRepo,
  GroupMemberRepo,
  GroupRepo,
  NotificationRepo,
  SessionRepo,
  TransactionRepo,
  UserRepo,
  WalletRepo,
} from './types';

/**
 * PostgreSQL repository implementations (spec §23–§25). Parameterised queries
 * only — no string interpolation of user input. Active when DATABASE_URL is
 * set; schema lives in database/schema.sql.
 */
export class PgUserRepo implements UserRepo {
  constructor(private readonly pool: Pool) {}

  async create(user: Omit<User, 'id' | 'created_at' | 'updated_at'>): Promise<User> {
    const row = await this.pool.query(
      `INSERT INTO users (full_name, phone, email, password_hash, kyc_status, verified)
       VALUES ($1, $2, $3, $4, $5, $6)
       RETURNING *`,
      [user.full_name, user.phone, user.email ?? null, user.password_hash, user.kyc_status, user.verified],
    );
    return rowToUser(row.rows[0]);
  }

  async findById(id: string): Promise<User | null> {
    const row = await this.pool.query('SELECT * FROM users WHERE id = $1', [id]);
    return row.rows[0] ? rowToUser(row.rows[0]) : null;
  }

  async findByPhoneOrEmail(identifier: string): Promise<User | null> {
    const raw = identifier.trim().toLowerCase();
    const normalized = normalizeIdentifier(raw);
    const row = await this.pool.query(
      `SELECT * FROM users
       WHERE replace(phone, ' ', '') IN ($1, $2) OR lower(email) = $3
       LIMIT 1`,
      [raw, normalized, raw],
    );
    return row.rows[0] ? rowToUser(row.rows[0]) : null;
  }

  async updateProfile(
    id: string,
    patch: { full_name?: string; phone?: string; email?: string | null },
  ): Promise<User> {
    const row = await this.pool.query(
      `UPDATE users SET
         full_name = COALESCE($2, full_name),
         phone = COALESCE($3, phone),
         email = COALESCE($4, email),
         updated_at = now()
       WHERE id = $1 RETURNING *`,
      [id, patch.full_name ?? null, patch.phone ?? null, patch.email ?? null],
    );
    return rowToUser(row.rows[0]);
  }

  async updatePassword(id: string, passwordHash: string): Promise<void> {
    await this.pool.query('UPDATE users SET password_hash = $2, updated_at = now() WHERE id = $1', [
      id,
      passwordHash,
    ]);
  }
}

export class PgSessionRepo implements SessionRepo {
  constructor(private readonly pool: Pool) {}

  async create(session: Omit<Session, 'created_at'>): Promise<Session> {
    const row = await this.pool.query(
      `INSERT INTO sessions (id, user_id, refresh_token_hash, expires_at, revoked_at)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [session.id, session.user_id, session.refresh_token_hash, session.expires_at, session.revoked_at ?? null],
    );
    return rowToSession(row.rows[0]);
  }

  async findActiveById(id: string): Promise<Session | null> {
    const row = await this.pool.query(
      `SELECT * FROM sessions
       WHERE id = $1 AND revoked_at IS NULL AND expires_at > now()
       LIMIT 1`,
      [id],
    );
    return row.rows[0] ? rowToSession(row.rows[0]) : null;
  }

  async revoke(id: string): Promise<void> {
    await this.pool.query('UPDATE sessions SET revoked_at = now() WHERE id = $1', [id]);
  }

  async revokeAllForUser(userId: string): Promise<void> {
    await this.pool.query('UPDATE sessions SET revoked_at = now() WHERE user_id = $1', [userId]);
  }
}

export class PgGroupRepo implements GroupRepo {
  constructor(private readonly pool: Pool) {}

  async create(group: Omit<SusuGroup, 'created_at' | 'updated_at'>): Promise<SusuGroup> {
    const row = await this.pool.query(
      `INSERT INTO susu_groups (id, owner_id, name, type, description, currency, status, rules)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8) RETURNING *`,
      [group.id, group.owner_id, group.name, group.type, group.description ?? null, group.currency, group.status, JSON.stringify(group.rules)],
    );
    return rowToGroup(row.rows[0]);
  }

  async findById(id: string): Promise<SusuGroup | null> {
    const row = await this.pool.query('SELECT * FROM susu_groups WHERE id = $1', [id]);
    return row.rows[0] ? rowToGroup(row.rows[0]) : null;
  }

  async listForUser(userId: string): Promise<SusuGroup[]> {
    const rows = await this.pool.query(
      `SELECT g.* FROM susu_groups g
       JOIN group_members m ON m.group_id = g.id
       WHERE m.user_id = $1
       ORDER BY g.created_at DESC`,
      [userId],
    );
    return rows.rows.map(rowToGroup);
  }

  async updateStatus(id: string, status: SusuGroup['status']): Promise<void> {
    await this.pool.query('UPDATE susu_groups SET status = $2, updated_at = now() WHERE id = $1', [
      id,
      status,
    ]);
  }
}

export class PgGroupMemberRepo implements GroupMemberRepo {
  constructor(private readonly pool: Pool) {}

  async add(member: GroupMember): Promise<GroupMember> {
    const row = await this.pool.query(
      `INSERT INTO group_members (group_id, user_id, role, joined_at, permissions)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [member.group_id, member.user_id, member.role, member.joined_at, JSON.stringify(member.permissions)],
    );
    return rowToMember(row.rows[0]);
  }

  async find(groupId: string, userId: string): Promise<GroupMember | null> {
    const row = await this.pool.query(
      'SELECT * FROM group_members WHERE group_id = $1 AND user_id = $2 LIMIT 1',
      [groupId, userId],
    );
    return row.rows[0] ? rowToMember(row.rows[0]) : null;
  }

  async list(groupId: string): Promise<GroupMember[]> {
    const rows = await this.pool.query('SELECT * FROM group_members WHERE group_id = $1', [groupId]);
    return rows.rows.map(rowToMember);
  }

  async updateRole(groupId: string, userId: string, role: GroupMember['role']): Promise<void> {
    await this.pool.query('UPDATE group_members SET role = $3 WHERE group_id = $1 AND user_id = $2', [
      groupId,
      userId,
      role,
    ]);
  }

  async remove(groupId: string, userId: string): Promise<void> {
    await this.pool.query('DELETE FROM group_members WHERE group_id = $1 AND user_id = $2', [
      groupId,
      userId,
    ]);
  }
}

export class PgWalletRepo implements WalletRepo {
  constructor(private readonly pool: Pool) {}

  async createPersonal(userId: string, currency: string): Promise<Wallet> {
    const row = await this.pool.query(
      `INSERT INTO wallets (owner_user_id, group_id, balance_minor, currency)
       VALUES ($1, NULL, 0, $2) RETURNING *`,
      [userId, currency],
    );
    return rowToWallet(row.rows[0]);
  }

  async createGroupWallet(groupId: string, currency: string): Promise<Wallet> {
    const row = await this.pool.query(
      `INSERT INTO wallets (owner_user_id, group_id, balance_minor, currency)
       VALUES (NULL, $1, 0, $2) RETURNING *`,
      [groupId, currency],
    );
    return rowToWallet(row.rows[0]);
  }

  async findPersonal(userId: string): Promise<Wallet | null> {
    const row = await this.pool.query(
      'SELECT * FROM wallets WHERE owner_user_id = $1 AND group_id IS NULL LIMIT 1',
      [userId],
    );
    return row.rows[0] ? rowToWallet(row.rows[0]) : null;
  }

  async findByGroup(groupId: string): Promise<Wallet | null> {
    const row = await this.pool.query(
      'SELECT * FROM wallets WHERE group_id = $1 AND owner_user_id IS NULL LIMIT 1',
      [groupId],
    );
    return row.rows[0] ? rowToWallet(row.rows[0]) : null;
  }

  async findById(id: string): Promise<Wallet | null> {
    const row = await this.pool.query('SELECT * FROM wallets WHERE id = $1', [id]);
    return row.rows[0] ? rowToWallet(row.rows[0]) : null;
  }

  async updateBalance(id: string, balanceMinor: number): Promise<void> {
    await this.pool.query('UPDATE wallets SET balance_minor = $2, updated_at = now() WHERE id = $1', [
      id,
      balanceMinor,
    ]);
  }
}

export class PgTransactionRepo implements TransactionRepo {
  constructor(private readonly pool: Pool) {}

  async create(transaction: Transaction): Promise<Transaction> {
    const row = await this.pool.query(
      `INSERT INTO transactions
         (id, user_id, group_id, wallet_id, amount_minor, currency, type, status,
          reference, idempotency_key, payment_method, metadata, created_at, created_by, approved_by)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14,$15)
       RETURNING *`,
      [
        transaction.id, transaction.user_id, transaction.group_id ?? null, transaction.wallet_id,
        transaction.amount_minor, transaction.currency, transaction.type, transaction.status,
        transaction.reference, transaction.idempotency_key ?? null, transaction.payment_method ?? null,
        transaction.metadata ? JSON.stringify(transaction.metadata) : null,
        transaction.created_at, transaction.created_by, transaction.approved_by ?? null,
      ],
    );
    return rowToTransaction(row.rows[0]);
  }

  async findById(id: string): Promise<Transaction | null> {
    const row = await this.pool.query('SELECT * FROM transactions WHERE id = $1', [id]);
    return row.rows[0] ? rowToTransaction(row.rows[0]) : null;
  }

  async findByIdempotencyKey(key: string): Promise<Transaction | null> {
    const row = await this.pool.query(
      'SELECT * FROM transactions WHERE idempotency_key = $1 LIMIT 1',
      [key],
    );
    return row.rows[0] ? rowToTransaction(row.rows[0]) : null;
  }

  async listForUser(
    userId: string,
    filters?: { type?: string; status?: string },
  ): Promise<Transaction[]> {
    const conditions = ['user_id = $1'];
    const params: unknown[] = [userId];
    if (filters?.type) {
      params.push(filters.type);
      conditions.push(`type = $${params.length}`);
    }
    if (filters?.status) {
      params.push(filters.status);
      conditions.push(`status = $${params.length}`);
    }
    const rows = await this.pool.query(
      `SELECT * FROM transactions WHERE ${conditions.join(' AND ')}
       ORDER BY created_at DESC`,
      params,
    );
    return rows.rows.map(rowToTransaction);
  }

  async updateStatus(id: string, status: Transaction['status']): Promise<void> {
    await this.pool.query('UPDATE transactions SET status = $2 WHERE id = $1', [id, status]);
  }
}

export class PgAuditRepo implements AuditRepo {
  constructor(private readonly pool: Pool) {}

  async log(entry: Omit<AuditLog, 'id' | 'created_at'>): Promise<AuditLog> {
    const row = await this.pool.query(
      `INSERT INTO audit_logs (user_id, action, entity_type, entity_id, metadata)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [
        entry.user_id ?? null,
        entry.action,
        entry.entity_type ?? null,
        entry.entity_id ?? null,
        entry.metadata ? JSON.stringify(entry.metadata) : null,
      ],
    );
    return rowToAudit(row.rows[0]);
  }

  async listForEntity(entityType: string, entityId: string): Promise<AuditLog[]> {
    const rows = await this.pool.query(
      'SELECT * FROM audit_logs WHERE entity_type = $1 AND entity_id = $2 ORDER BY created_at DESC',
      [entityType, entityId],
    );
    return rows.rows.map(rowToAudit);
  }
}

export class PgNotificationRepo implements NotificationRepo {
  constructor(private readonly pool: Pool) {}

  async create(notification: Omit<Notification, 'id' | 'created_at'>): Promise<Notification> {
    const row = await this.pool.query(
      `INSERT INTO notifications (user_id, title, body, category, read)
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [notification.user_id, notification.title, notification.body, notification.category, notification.read],
    );
    return rowToNotification(row.rows[0]);
  }

  async listForUser(userId: string): Promise<Notification[]> {
    const rows = await this.pool.query(
      'SELECT * FROM notifications WHERE user_id = $1 ORDER BY created_at DESC',
      [userId],
    );
    return rows.rows.map(rowToNotification);
  }

  async unreadCount(userId: string): Promise<number> {
    const row = await this.pool.query(
      'SELECT count(*)::int AS count FROM notifications WHERE user_id = $1 AND NOT read',
      [userId],
    );
    return row.rows[0].count as number;
  }

  async markRead(id: string, userId: string): Promise<void> {
    await this.pool.query(
      'UPDATE notifications SET read = true WHERE id = $1 AND user_id = $2',
      [id, userId],
    );
  }

  async markAllRead(userId: string): Promise<void> {
    await this.pool.query('UPDATE notifications SET read = true WHERE user_id = $1', [userId]);
  }
}

/** Normalizes a phone identifier to 233-prefix form for matching. */
function normalizeIdentifier(value: string): string {
  let digits = value.replace(/[\s\-()]/g, '');
  if (digits.startsWith('+')) digits = digits.slice(1);
  if (digits.startsWith('0')) digits = `233${digits.slice(1)}`;
  return digits;
}

// ---------------------------------------------------------------------------
// Row mappers
// ---------------------------------------------------------------------------

function rowToUser(row: QueryResultRow): User {
  return {
    id: row.id, full_name: row.full_name, phone: row.phone, email: row.email,
    password_hash: row.password_hash, kyc_status: row.kyc_status,
    verified: row.verified, created_at: row.created_at, updated_at: row.updated_at,
  };
}

function rowToSession(row: QueryResultRow): Session {
  return {
    id: row.id, user_id: row.user_id, refresh_token_hash: row.refresh_token_hash,
    expires_at: row.expires_at, created_at: row.created_at, revoked_at: row.revoked_at,
  };
}

function rowToGroup(row: QueryResultRow): SusuGroup {
  return {
    id: row.id, owner_id: row.owner_id, name: row.name, type: row.type,
    description: row.description, currency: row.currency, status: row.status,
    rules: typeof row.rules === 'string' ? JSON.parse(row.rules) : row.rules ?? {},
    created_at: row.created_at, updated_at: row.updated_at,
  };
}

function rowToMember(row: QueryResultRow): GroupMember {
  return {
    group_id: row.group_id, user_id: row.user_id, role: row.role, joined_at: row.joined_at,
    permissions: typeof row.permissions === 'string' ? JSON.parse(row.permissions) : row.permissions ?? [],
  };
}

function rowToWallet(row: QueryResultRow): Wallet {
  return {
    id: row.id, owner_user_id: row.owner_user_id, group_id: row.group_id,
    balance_minor: row.balance_minor, currency: row.currency,
    created_at: row.created_at, updated_at: row.updated_at,
  };
}

function rowToTransaction(row: QueryResultRow): Transaction {
  return {
    id: row.id, user_id: row.user_id, group_id: row.group_id, wallet_id: row.wallet_id,
    amount_minor: row.amount_minor, currency: row.currency, type: row.type, status: row.status,
    reference: row.reference, idempotency_key: row.idempotency_key,
    payment_method: row.payment_method,
    metadata: typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata ?? null,
    created_at: row.created_at, created_by: row.created_by, approved_by: row.approved_by,
  };
}

function rowToAudit(row: QueryResultRow): AuditLog {
  return {
    id: row.id, user_id: row.user_id, action: row.action,
    entity_type: row.entity_type, entity_id: row.entity_id,
    metadata: typeof row.metadata === 'string' ? JSON.parse(row.metadata) : row.metadata ?? null,
    created_at: row.created_at,
  };
}

function rowToNotification(row: QueryResultRow): Notification {
  return {
    id: row.id, user_id: row.user_id, title: row.title, body: row.body,
    category: row.category, read: row.read, created_at: row.created_at,
  };
}
