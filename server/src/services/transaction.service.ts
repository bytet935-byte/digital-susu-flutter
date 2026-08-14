import { Transaction } from '../models';
import { TransactionRepo } from '../repositories/types';

/**
 * Transaction history queries (spec §14). Filtering is applied at the
 * repository level with indexes in PostgreSQL mode.
 */
export class TransactionService {
  constructor(private readonly transactions: TransactionRepo) {}

  listForUser(
    userId: string,
    filters?: { type?: string; status?: string },
  ): Promise<Transaction[]> {
    return this.transactions.listForUser(userId, filters);
  }
}
