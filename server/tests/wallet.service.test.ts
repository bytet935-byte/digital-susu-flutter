import { beforeEach, describe, expect, it } from 'vitest';

import {
  MemoryAuditRepo,
  MemoryGroupMemberRepo,
  MemoryTransactionRepo,
  MemoryWalletRepo,
  resetMemoryStore,
} from '../src/repositories/memory.repos';
import { WalletService } from '../src/services/wallet.service';
import { GroupService } from '../src/services/group.service';
import { MemoryGroupRepo, MemoryUserRepo } from '../src/repositories/memory.repos';
import { AuthService } from '../src/services/auth.service';
import { MemorySessionRepo } from '../src/repositories/memory.repos';

function build() {
  const users = new MemoryUserRepo();
  const sessions = new MemorySessionRepo();
  const groups = new MemoryGroupRepo();
  const members = new MemoryGroupMemberRepo();
  const wallets = new MemoryWalletRepo();
  const transactions = new MemoryTransactionRepo();
  const audit = new MemoryAuditRepo();

  const auth = new AuthService(users, sessions, wallets, audit);
  const groupService = new GroupService(groups, members, users, audit);
  const walletService = new WalletService(wallets, transactions, members, audit);
  return { auth, groupService, walletService, users };
}

describe('WalletService (spec §7, §8, §28)', () => {
  beforeEach(() => {
    resetMemoryStore();
  });

  it('top-up increases the personal wallet and records a transaction', async () => {
    const { auth, walletService } = build();
    const { user } = await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' });

    const txn = await walletService.topUp({
      userId: user.id, amountMinor: 20000, paymentMethod: 'MTN Mobile Money', idempotencyKey: 'k-1',
    });

    expect(txn.status).toBe('SUCCESSFUL');
    expect(txn.type).toBe('DEPOSIT');
    const wallet = await walletService.getPersonalWallet(user.id);
    expect(wallet.balance_minor).toBe(20000);
  });

  it('is idempotent — replaying a key returns the same transaction', async () => {
    const { auth, walletService } = build();
    const { user } = await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' });

    const first = await walletService.topUp({
      userId: user.id, amountMinor: 10000, paymentMethod: 'MoMo', idempotencyKey: 'dup-key',
    });
    const replay = await walletService.topUp({
      userId: user.id, amountMinor: 10000, paymentMethod: 'MoMo', idempotencyKey: 'dup-key',
    });

    expect(replay.id).toBe(first.id);
    const wallet = await walletService.getPersonalWallet(user.id);
    expect(wallet.balance_minor).toBe(10000); // credited exactly once
  });

  it('rejects withdrawals beyond the balance (no negative balances)', async () => {
    const { auth, walletService } = build();
    const { user } = await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' });
    await walletService.topUp({ userId: user.id, amountMinor: 5000, paymentMethod: 'MoMo', idempotencyKey: 'k-1' });

    await expect(
      walletService.withdraw({ userId: user.id, amountMinor: 5001, paymentMethod: 'Bank', idempotencyKey: 'k-2' }),
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('rejects zero/negative amounts', async () => {
    const { auth, walletService } = build();
    const { user } = await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' });

    await expect(
      walletService.topUp({ userId: user.id, amountMinor: 0, paymentMethod: 'MoMo', idempotencyKey: 'k-1' }),
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('keeps group money strictly separate from personal money (spec §7)', async () => {
    const { auth, groupService, walletService } = build();
    const a = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const b = (await auth.register({ fullName: 'B', identifier: '0551234567', password: 'secret1' })).user;

    const group = await groupService.create({
      ownerId: a.id, name: 'Weekend Susu', type: 'ROTATIONAL_SUSU',
    });
    await groupService.addMember({ actorId: a.id, groupId: group.id, identifier: '0551234567' });

    // A contributes to the group wallet…
    const contribution = await walletService.contribute({
      userId: a.id, groupId: group.id, amountMinor: 5000, paymentMethod: 'MoMo', idempotencyKey: 'k-1',
    });
    const groupWallet = await walletService.getGroupWallet(group.id, a.id);
    expect(contribution.group_id).toBe(group.id);
    expect(groupWallet.balance_minor).toBe(5000);

    // …but A's personal wallet is untouched (strict separation).
    const personalWallet = await walletService.getPersonalWallet(a.id);
    expect(personalWallet.balance_minor).toBe(0);
    expect(personalWallet.id).not.toBe(groupWallet.id);
  });

  it('blocks contributions from non-members (permission enforcement, spec §27)', async () => {
    const { auth, groupService, walletService } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const outsider = (await auth.register({ fullName: 'C', identifier: '0501234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'Weekend Susu', type: 'ROTATIONAL_SUSU' });

    await expect(
      walletService.contribute({
        userId: outsider.id, groupId: group.id, amountMinor: 1000, paymentMethod: 'MoMo', idempotencyKey: 'k-1',
      }),
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});
