import { pool } from './db/pool';
import {
  MemoryAuditRepo,
  MemoryGroupMemberRepo,
  MemoryGroupRepo,
  MemoryNotificationRepo,
  MemorySessionRepo,
  MemoryTransactionRepo,
  MemoryUserRepo,
  MemoryWalletRepo,
} from './repositories/memory.repos';
import {
  PgAuditRepo,
  PgGroupMemberRepo,
  PgGroupRepo,
  PgNotificationRepo,
  PgSessionRepo,
  PgTransactionRepo,
  PgUserRepo,
  PgWalletRepo,
} from './repositories/pg.repos';
import { AuthService } from './services/auth.service';
import { GroupService } from './services/group.service';
import { TransactionService } from './services/transaction.service';
import { WalletService } from './services/wallet.service';

/**
 * Dependency wiring (spec §23): PostgreSQL when DATABASE_URL is configured,
 * in-memory otherwise. Services only ever see repository interfaces.
 */
export function buildContainer() {
  if (pool) {
    return {
      mode: 'postgres' as const,
      auth: new AuthService(
        new PgUserRepo(pool), new PgSessionRepo(pool),
        new PgWalletRepo(pool), new PgAuditRepo(pool),
      ),
      groups: new GroupService(
        new PgGroupRepo(pool), new PgGroupMemberRepo(pool),
        new PgUserRepo(pool), new PgAuditRepo(pool),
      ),
      wallets: new WalletService(
        new PgWalletRepo(pool), new PgTransactionRepo(pool),
        new PgGroupMemberRepo(pool), new PgAuditRepo(pool),
      ),
      transactions: new TransactionService(new PgTransactionRepo(pool)),
      notifications: new PgNotificationRepo(pool),
      audit: new PgAuditRepo(pool),
    };
  }

  return {
    mode: 'memory' as const,
    auth: new AuthService(
      new MemoryUserRepo(), new MemorySessionRepo(),
      new MemoryWalletRepo(), new MemoryAuditRepo(),
    ),
    groups: new GroupService(
      new MemoryGroupRepo(), new MemoryGroupMemberRepo(),
      new MemoryUserRepo(), new MemoryAuditRepo(),
    ),
    wallets: new WalletService(
      new MemoryWalletRepo(), new MemoryTransactionRepo(),
      new MemoryGroupMemberRepo(), new MemoryAuditRepo(),
    ),
    transactions: new TransactionService(new MemoryTransactionRepo()),
    notifications: new MemoryNotificationRepo(),
    audit: new MemoryAuditRepo(),
  };
}

export type Container = ReturnType<typeof buildContainer>;
