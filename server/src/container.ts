import { pool } from './db/pool';
import {
  MemoryAuditRepo,
  MemoryGroupMemberRepo,
  MemoryGroupRepo,
  MemoryMessageRepo,
  MemoryNotificationRepo,
  MemoryProposalRepo,
  MemorySessionRepo,
  MemoryTransactionRepo,
  MemoryUserRepo,
  MemoryWalletRepo,
} from './repositories/memory.repos';
import {
  PgAuditRepo,
  PgGroupMemberRepo,
  PgGroupRepo,
  PgMessageRepo,
  PgNotificationRepo,
  PgProposalRepo,
  PgSessionRepo,
  PgTransactionRepo,
  PgUserRepo,
  PgWalletRepo,
} from './repositories/pg.repos';
import { AuthService } from './services/auth.service';
import { ChatService } from './services/chat.service';
import { GovernanceService } from './services/governance.service';
import { GroupService } from './services/group.service';
import { NotificationService } from './services/notification.service';
import { TransactionService } from './services/transaction.service';
import { WalletService } from './services/wallet.service';

/**
 * Dependency wiring (spec §23): PostgreSQL when DATABASE_URL is configured,
 * in-memory otherwise. Services only ever see repository interfaces.
 */
export function buildContainer() {
  if (pool) {
    const pg = {
      users: new PgUserRepo(pool), sessions: new PgSessionRepo(pool),
      groups: new PgGroupRepo(pool), members: new PgGroupMemberRepo(pool),
      wallets: new PgWalletRepo(pool), transactions: new PgTransactionRepo(pool),
      messages: new PgMessageRepo(pool), proposals: new PgProposalRepo(pool),
      notifications: new PgNotificationRepo(pool), audit: new PgAuditRepo(pool),
    };
    return {
      mode: 'postgres' as const,
      auth: new AuthService(pg.users, pg.sessions, pg.wallets, pg.audit),
      groups: new GroupService(pg.groups, pg.members, pg.users, pg.audit),
      wallets: new WalletService(pg.wallets, pg.transactions, pg.members, pg.audit, pg.notifications),
      transactions: new TransactionService(pg.transactions),
      chat: new ChatService(pg.messages, pg.members, pg.audit),
      notifications: new NotificationService(pg.notifications),
      governance: new GovernanceService(pg.proposals, pg.members, pg.audit),
      audit: pg.audit,
    };
  }

  const mem = {
    users: new MemoryUserRepo(), sessions: new MemorySessionRepo(),
    groups: new MemoryGroupRepo(), members: new MemoryGroupMemberRepo(),
    wallets: new MemoryWalletRepo(), transactions: new MemoryTransactionRepo(),
    messages: new MemoryMessageRepo(), proposals: new MemoryProposalRepo(),
    notifications: new MemoryNotificationRepo(), audit: new MemoryAuditRepo(),
  };
  return {
    mode: 'memory' as const,
    auth: new AuthService(mem.users, mem.sessions, mem.wallets, mem.audit),
    groups: new GroupService(mem.groups, mem.members, mem.users, mem.audit),
    wallets: new WalletService(mem.wallets, mem.transactions, mem.members, mem.audit, mem.notifications),
    transactions: new TransactionService(mem.transactions),
    chat: new ChatService(mem.messages, mem.members, mem.audit),
    notifications: new NotificationService(mem.notifications),
    governance: new GovernanceService(mem.proposals, mem.members, mem.audit),
    audit: mem.audit,
  };
}

export type Container = ReturnType<typeof buildContainer>;
