import { randomUUID } from 'crypto';

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
 * Shared in-memory store — the dev/test persistence layer. Instances of each
 * repo share one store so data stays consistent across repos.
 */
export class MemoryStore {
  users: User[] = [];
  sessions: Session[] = [];
  groups: SusuGroup[] = [];
  members: GroupMember[] = [];
  wallets: Wallet[] = [];
  transactions: Transaction[] = [];
  audit: AuditLog[] = [];
  notifications: Notification[] = [];
}

let shared: MemoryStore | null = null;

/** Returns the process-wide store (reset in tests via `resetMemoryStore`). */
export function getMemoryStore(): MemoryStore {
  shared ??= new MemoryStore();
  return shared;
}

export function resetMemoryStore(): void {
  shared = new MemoryStore();
}

function now(): string {
  return new Date().toISOString();
}

/** Normalizes a phone identifier to 233-prefix form for matching. */
function normalizeIdentifier(value: string): string {
  let digits = value.replace(/[\s\-()]/g, '');
  if (digits.startsWith('+')) digits = digits.slice(1);
  if (digits.startsWith('0')) digits = `233${digits.slice(1)}`;
  return digits;
}

export class MemoryUserRepo implements UserRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async create(user: Omit<User, 'id' | 'created_at' | 'updated_at'>): Promise<User> {
    const record: User = {
      ...user,
      id: `usr_${randomUUID()}`,
      created_at: now(),
      updated_at: now(),
    };
    this.store.users.push(record);
    return record;
  }

  async findById(id: string): Promise<User | null> {
    return this.store.users.find((u) => u.id === id) ?? null;
  }

  async findByPhoneOrEmail(identifier: string): Promise<User | null> {
    const raw = identifier.trim().toLowerCase();
    const normalized = normalizeIdentifier(raw);
    return (
      this.store.users.find((u) => {
        const phone = u.phone.replace(/[\s\-()]/g, '').toLowerCase();
        const email = (u.email ?? '').toLowerCase();
        return phone === raw || phone === normalized || email === raw;
      }) ?? null
    );
  }

  async updateProfile(
    id: string,
    patch: { full_name?: string; phone?: string; email?: string | null },
  ): Promise<User> {
    const user = await this.findById(id);
    if (!user) throw new Error('user not found');
    Object.assign(user, patch, { updated_at: now() });
    return user;
  }

  async updatePassword(id: string, passwordHash: string): Promise<void> {
    const user = await this.findById(id);
    if (user) {
      user.password_hash = passwordHash;
      user.updated_at = now();
    }
  }
}

export class MemorySessionRepo implements SessionRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async create(
    session: Omit<Session, 'created_at'>,
  ): Promise<Session> {
    const record: Session = { ...session, created_at: now() };
    this.store.sessions.push(record);
    return record;
  }

  async findActiveById(id: string): Promise<Session | null> {
    const session = this.store.sessions.find((s) => s.id === id) ?? null;
    if (!session || session.revoked_at || new Date(session.expires_at) < new Date()) {
      return null;
    }
    return session;
  }

  async revoke(id: string): Promise<void> {
    const session = this.store.sessions.find((s) => s.id === id);
    if (session) session.revoked_at = now();
  }

  async revokeAllForUser(userId: string): Promise<void> {
    for (const session of this.store.sessions) {
      if (session.user_id === userId) session.revoked_at = now();
    }
  }
}

export class MemoryGroupRepo implements GroupRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async create(
    group: Omit<SusuGroup, 'created_at' | 'updated_at'>,
  ): Promise<SusuGroup> {
    const record: SusuGroup = {
      ...group,
      created_at: now(),
      updated_at: now(),
    };
    this.store.groups.push(record);
    return record;
  }

  async findById(id: string): Promise<SusuGroup | null> {
    return this.store.groups.find((g) => g.id === id) ?? null;
  }

  async listForUser(userId: string): Promise<SusuGroup[]> {
    const groupIds = new Set(
      this.store.members.filter((m) => m.user_id === userId).map((m) => m.group_id),
    );
    return this.store.groups.filter((g) => groupIds.has(g.id));
  }

  async updateStatus(id: string, status: SusuGroup['status']): Promise<void> {
    const group = this.store.groups.find((g) => g.id === id);
    if (group) {
      group.status = status;
      group.updated_at = now();
    }
  }
}

export class MemoryGroupMemberRepo implements GroupMemberRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async add(member: GroupMember): Promise<GroupMember> {
    this.store.members.push(member);
    return member;
  }

  async find(groupId: string, userId: string): Promise<GroupMember | null> {
    return (
      this.store.members.find(
        (m) => m.group_id === groupId && m.user_id === userId,
      ) ?? null
    );
  }

  async list(groupId: string): Promise<GroupMember[]> {
    return this.store.members.filter((m) => m.group_id === groupId);
  }

  async updateRole(
    groupId: string,
    userId: string,
    role: GroupMember['role'],
  ): Promise<void> {
    const member = await this.find(groupId, userId);
    if (member) member.role = role;
  }

  async remove(groupId: string, userId: string): Promise<void> {
    this.store.members = this.store.members.filter(
      (m) => !(m.group_id === groupId && m.user_id === userId),
    );
  }
}

export class MemoryWalletRepo implements WalletRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async createPersonal(userId: string, currency: string): Promise<Wallet> {
    const wallet: Wallet = {
      id: `wal_${randomUUID()}`,
      owner_user_id: userId,
      group_id: null,
      balance_minor: 0,
      currency,
      created_at: now(),
      updated_at: now(),
    };
    this.store.wallets.push(wallet);
    return wallet;
  }

  async createGroupWallet(groupId: string, currency: string): Promise<Wallet> {
    const wallet: Wallet = {
      id: `gwal_${randomUUID()}`,
      owner_user_id: null,
      group_id: groupId,
      balance_minor: 0,
      currency,
      created_at: now(),
      updated_at: now(),
    };
    this.store.wallets.push(wallet);
    return wallet;
  }

  async findPersonal(userId: string): Promise<Wallet | null> {
    return (
      this.store.wallets.find(
        (w) => w.owner_user_id === userId && w.group_id === null,
      ) ?? null
    );
  }

  async findByGroup(groupId: string): Promise<Wallet | null> {
    return this.store.wallets.find((w) => w.group_id === groupId) ?? null;
  }

  async findById(id: string): Promise<Wallet | null> {
    return this.store.wallets.find((w) => w.id === id) ?? null;
  }

  async updateBalance(id: string, balanceMinor: number): Promise<void> {
    const wallet = this.store.wallets.find((w) => w.id === id);
    if (wallet) {
      wallet.balance_minor = balanceMinor;
      wallet.updated_at = now();
    }
  }
}

export class MemoryTransactionRepo implements TransactionRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async create(transaction: Transaction): Promise<Transaction> {
    this.store.transactions.push(transaction);
    return transaction;
  }

  async findById(id: string): Promise<Transaction | null> {
    return this.store.transactions.find((t) => t.id === id) ?? null;
  }

  async findByIdempotencyKey(key: string): Promise<Transaction | null> {
    return (
      this.store.transactions.find((t) => t.idempotency_key === key) ?? null
    );
  }

  async listForUser(
    userId: string,
    filters?: { type?: string; status?: string },
  ): Promise<Transaction[]> {
    return this.store.transactions
      .filter((t) => t.user_id === userId)
      .filter((t) => (filters?.type ? t.type === filters.type : true))
      .filter((t) => (filters?.status ? t.status === filters.status : true))
      .sort((a, b) => b.created_at.localeCompare(a.created_at));
  }

  async updateStatus(id: string, status: Transaction['status']): Promise<void> {
    const transaction = this.store.transactions.find((t) => t.id === id);
    if (transaction) transaction.status = status;
  }
}

export class MemoryAuditRepo implements AuditRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async log(
    entry: Omit<AuditLog, 'id' | 'created_at'>,
  ): Promise<AuditLog> {
    const record: AuditLog = { ...entry, id: `aud_${randomUUID()}`, created_at: now() };
    this.store.audit.push(record);
    return record;
  }

  async listForEntity(entityType: string, entityId: string): Promise<AuditLog[]> {
    return this.store.audit.filter(
      (a) => a.entity_type === entityType && a.entity_id === entityId,
    );
  }
}

export class MemoryNotificationRepo implements NotificationRepo {
  private get store(): MemoryStore {
    return getMemoryStore();
  }

  async create(
    notification: Omit<Notification, 'id' | 'created_at'>,
  ): Promise<Notification> {
    const record: Notification = {
      ...notification,
      id: `ntf_${randomUUID()}`,
      created_at: now(),
    };
    this.store.notifications.push(record);
    return record;
  }

  async listForUser(userId: string): Promise<Notification[]> {
    return this.store.notifications
      .filter((n) => n.user_id === userId)
      .sort((a, b) => b.created_at.localeCompare(a.created_at));
  }

  async unreadCount(userId: string): Promise<number> {
    return this.store.notifications.filter(
      (n) => n.user_id === userId && !n.read,
    ).length;
  }

  async markRead(id: string, userId: string): Promise<void> {
    const notification = this.store.notifications.find(
      (n) => n.id === id && n.user_id === userId,
    );
    if (notification) notification.read = true;
  }

  async markAllRead(userId: string): Promise<void> {
    for (const notification of this.store.notifications) {
      if (notification.user_id === userId) notification.read = true;
    }
  }
}
