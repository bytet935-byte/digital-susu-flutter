import {
  AuditLog,
  GroupMember,
  GroupMessage,
  Notification,
  Proposal,
  ProposalVote,
  PublicUser,
  Session,
  SusuGroup,
  Transaction,
  User,
  Wallet,
} from '../models';

/**
 * Repository contracts. Two implementations exist:
 *  - memory.repos.ts — in-memory (dev/tests, no DATABASE_URL)
 *  - pg.repos.ts    — PostgreSQL (production)
 * Services depend only on these interfaces (spec §22, §23, §30).
 */
export interface UserRepo {
  create(user: Omit<User, 'id' | 'created_at' | 'updated_at'>): Promise<User>;
  findById(id: string): Promise<User | null>;
  findByPhoneOrEmail(identifier: string): Promise<User | null>;
  updateProfile(
    id: string,
    patch: { full_name?: string; phone?: string; email?: string | null },
  ): Promise<User>;
  updatePassword(id: string, passwordHash: string): Promise<void>;
}

export interface SessionRepo {
  create(session: Omit<Session, 'created_at'>): Promise<Session>;
  findActiveById(id: string): Promise<Session | null>;
  revoke(id: string): Promise<void>;
  revokeAllForUser(userId: string): Promise<void>;
}

export interface GroupRepo {
  create(group: Omit<SusuGroup, 'created_at' | 'updated_at'>): Promise<SusuGroup>;
  findById(id: string): Promise<SusuGroup | null>;
  listForUser(userId: string): Promise<SusuGroup[]>;
  updateStatus(id: string, status: SusuGroup['status']): Promise<void>;
}

export interface GroupMemberRepo {
  add(member: GroupMember): Promise<GroupMember>;
  find(groupId: string, userId: string): Promise<GroupMember | null>;
  list(groupId: string): Promise<GroupMember[]>;
  updateRole(
    groupId: string,
    userId: string,
    role: GroupMember['role'],
  ): Promise<void>;
  remove(groupId: string, userId: string): Promise<void>;
}

export interface WalletRepo {
  createPersonal(userId: string, currency: string): Promise<Wallet>;
  createGroupWallet(groupId: string, currency: string): Promise<Wallet>;
  findPersonal(userId: string): Promise<Wallet | null>;
  findByGroup(groupId: string): Promise<Wallet | null>;
  findById(id: string): Promise<Wallet | null>;
  updateBalance(id: string, balanceMinor: number): Promise<void>;
}

export interface TransactionRepo {
  create(transaction: Transaction): Promise<Transaction>;
  findById(id: string): Promise<Transaction | null>;
  findByIdempotencyKey(key: string): Promise<Transaction | null>;
  listForUser(
    userId: string,
    filters?: { type?: string; status?: string },
  ): Promise<Transaction[]>;
  updateStatus(id: string, status: Transaction['status']): Promise<void>;
}

export interface AuditRepo {
  log(entry: Omit<AuditLog, 'id' | 'created_at'>): Promise<AuditLog>;
  listForEntity(entityType: string, entityId: string): Promise<AuditLog[]>;
}

export interface NotificationRepo {
  create(notification: Omit<Notification, 'id' | 'created_at'>): Promise<Notification>;
  listForUser(userId: string): Promise<Notification[]>;
  unreadCount(userId: string): Promise<number>;
  markRead(id: string, userId: string): Promise<void>;
  markAllRead(userId: string): Promise<void>;
}

export interface MessageRepo {
  create(message: Omit<GroupMessage, 'id' | 'created_at'>): Promise<GroupMessage>;
  listForGroup(groupId: string): Promise<GroupMessage[]>;
}

export interface ProposalRepo {
  create(proposal: Omit<Proposal, 'id' | 'created_at'>): Promise<Proposal>;
  findById(id: string): Promise<Proposal | null>;
  listForGroup(groupId: string): Promise<Proposal[]>;
  vote(vote: ProposalVote): Promise<ProposalVote>;
  findVote(proposalId: string, userId: string): Promise<ProposalVote | null>;
  updateStatus(id: string, status: Proposal['status'], result?: string | null): Promise<void>;
}
