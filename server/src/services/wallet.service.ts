import { randomUUID } from 'crypto';

import { Transaction, Wallet } from '../models';
import {
  AuditRepo,
  GroupMemberRepo,
  NotificationRepo,
  TransactionRepo,
  WalletRepo,
} from '../repositories/types';
import { ApiError } from '../utils/api-error';

/**
 * Wallet business rules (spec §7, §8, §13, §28).
 *
 * Strict separation is enforced structurally: a PERSONAL wallet has
 * `owner_user_id` (group_id null); a GROUP wallet has `group_id`
 * (owner_user_id null). A group transaction can never silently become a
 * personal transaction — the wallet used is chosen by context, and every
 * transaction carries wallet_id + user_id + optional group_id.
 *
 * Ledger changes are append-only: balance updates happen alongside a
 * transaction record; corrections create ADJUSTMENT/REVERSAL records.
 */
export class WalletService {
  constructor(
    private readonly wallets: WalletRepo,
    private readonly transactions: TransactionRepo,
    private readonly members: GroupMemberRepo,
    private readonly audit: AuditRepo,
    private readonly notifications: NotificationRepo,
  ) {}

  async getPersonalWallet(userId: string): Promise<Wallet> {
    const existing = await this.wallets.findPersonal(userId);
    if (existing) return existing;
    return this.wallets.createPersonal(userId, 'GHS');
  }

  /** Group wallet access requires membership (spec §7, §27). */
  async getGroupWallet(groupId: string, userId: string): Promise<Wallet> {
    const membership = await this.members.find(groupId, userId);
    if (!membership) {
      throw ApiError.forbidden('You are not a member of this group.');
    }
    const existing = await this.wallets.findByGroup(groupId);
    if (existing) return existing;
    return this.wallets.createGroupWallet(groupId, 'GHS');
  }

  async topUp(input: {
    userId: string;
    amountMinor: number;
    paymentMethod: string;
    idempotencyKey: string;
  }): Promise<Transaction> {
    this.assertPositive(input.amountMinor);
    return this.execute(input.userId, input.amountMinor, 'DEPOSIT', {
      wallet: await this.getPersonalWallet(input.userId),
      paymentMethod: input.paymentMethod,
      idempotencyKey: input.idempotencyKey,
      metadata: { description: 'Wallet top-up' },
    });
  }

  async withdraw(input: {
    userId: string;
    amountMinor: number;
    paymentMethod: string;
    idempotencyKey: string;
  }): Promise<Transaction> {
    this.assertPositive(input.amountMinor);
    const wallet = await this.getPersonalWallet(input.userId);
    if (wallet.balance_minor < input.amountMinor) {
      throw ApiError.badRequest('Insufficient balance for this withdrawal.');
    }
    return this.execute(input.userId, input.amountMinor, 'WITHDRAWAL', {
      wallet,
      paymentMethod: input.paymentMethod,
      idempotencyKey: input.idempotencyKey,
      metadata: { description: 'Wallet withdrawal' },
    });
  }

  /** Records a group contribution into the group wallet (spec §15, §7). */
  async contribute(input: {
    userId: string;
    groupId: string;
    amountMinor: number;
    paymentMethod: string;
    idempotencyKey: string;
  }): Promise<Transaction> {
    this.assertPositive(input.amountMinor);
    const wallet = await this.getGroupWallet(input.groupId, input.userId);
    return this.execute(input.userId, input.amountMinor, 'CONTRIBUTION', {
      wallet,
      groupId: input.groupId,
      paymentMethod: input.paymentMethod,
      idempotencyKey: input.idempotencyKey,
      metadata: { description: 'Group contribution' },
    });
  }

  /**
   * Core transactional flow: idempotency check → PENDING record → apply
   * balance → confirm → audit (spec §9, §15, §28).
   */
  private async execute(
    userId: string,
    amountMinor: number,
    type: string,
    options: {
      wallet: Wallet;
      groupId?: string;
      paymentMethod: string;
      idempotencyKey: string;
      metadata: Record<string, unknown>;
    },
  ): Promise<Transaction> {
    // Idempotency: a replayed request returns the original record (spec §28).
    const existing = await this.transactions.findByIdempotencyKey(
      options.idempotencyKey,
    );
    if (existing) return existing;

    const transaction: Transaction = {
      id: `txn_${randomUUID()}`,
      user_id: userId,
      group_id: options.groupId ?? null,
      wallet_id: options.wallet.id,
      amount_minor: amountMinor,
      currency: options.wallet.currency,
      type,
      status: 'PENDING',
      reference: `TXN-${Date.now().toString(36).toUpperCase()}`,
      idempotency_key: options.idempotencyKey,
      payment_method: options.paymentMethod,
      metadata: options.metadata,
      created_at: new Date().toISOString(),
      created_by: userId,
      approved_by: null,
    };
    await this.transactions.create(transaction);

    // Balance change happens with the record — never "because a button was
    // clicked" (spec §15) and never without a transaction row (spec §8).
    const newBalance = options.wallet.balance_minor + amountMinor;
    if (newBalance < 0) {
      throw ApiError.badRequest('Insufficient balance.');
    }
    await this.wallets.updateBalance(options.wallet.id, newBalance);
    await this.transactions.updateStatus(transaction.id, 'SUCCESSFUL');
    transaction.status = 'SUCCESSFUL';

    await this.audit.log({
      user_id: userId,
      action: `TRANSACTION_${type}`,
      entity_type: 'transaction',
      entity_id: transaction.id,
      metadata: { amount_minor: amountMinor, wallet_id: options.wallet.id },
    });

    await this.notifyActor(userId, type, amountMinor, options.wallet.currency);
    if (options.groupId) {
      await this.notifyGroupOwner(options.groupId, userId, amountMinor, options.wallet.currency);
    }

    return transaction;
  }

  private assertPositive(amountMinor: number): void {
    if (!Number.isInteger(amountMinor) || amountMinor <= 0) {
      throw ApiError.badRequest('Amount must be a positive whole number (pesewas).');
    }
  }

  private async notifyActor(
    userId: string,
    type: string,
    amountMinor: number,
    currency: string,
  ): Promise<void> {
    const amount = `GHS ${(amountMinor / 100).toFixed(2)}`;
    const title = type === 'DEPOSIT' ? 'Top-up successful' : `${type} recorded`;
    await this.notifications.create({
      user_id: userId,
      title,
      body: `Your ${type.toLowerCase()} of ${amount} was successful.`,
      category: 'payment_confirmation',
      read: false,
    });
  }

  private async notifyGroupOwner(
    groupId: string,
    actorId: string,
    amountMinor: number,
    currency: string,
  ): Promise<void> {
    const members = await this.members.list(groupId);
    const owner = members.find((m) => m.role === 'GROUP_OWNER');
    if (!owner || owner.user_id === actorId) return;
    await this.notifications.create({
      user_id: owner.user_id,
      title: 'New contribution',
      body: `A member contributed GHS ${(amountMinor / 100).toFixed(2)} to your group.`,
      category: 'contribution_reminder',
      read: false,
    });
  }
}