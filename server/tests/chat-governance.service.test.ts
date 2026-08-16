import { beforeEach, describe, expect, it } from 'vitest';

import {
  MemoryAuditRepo,
  MemoryGroupMemberRepo,
  MemoryGroupRepo,
  MemoryMessageRepo,
  MemoryProposalRepo,
  MemorySessionRepo,
  MemoryTransactionRepo,
  MemoryUserRepo,
  MemoryWalletRepo,
  resetMemoryStore,
} from '../src/repositories/memory.repos';
import { AuthService } from '../src/services/auth.service';
import { ChatService } from '../src/services/chat.service';
import { GovernanceService } from '../src/services/governance.service';
import { GroupService } from '../src/services/group.service';

function build() {
  const users = new MemoryUserRepo();
  const sessions = new MemorySessionRepo();
  const groups = new MemoryGroupRepo();
  const members = new MemoryGroupMemberRepo();
  const wallets = new MemoryWalletRepo();
  const transactions = new MemoryTransactionRepo();
  const messages = new MemoryMessageRepo();
  const proposals = new MemoryProposalRepo();
  const audit = new MemoryAuditRepo();

  const auth = new AuthService(users, sessions, wallets, audit);
  const groupService = new GroupService(groups, members, users, audit);
  const chat = new ChatService(messages, members, audit);
  const governance = new GovernanceService(proposals, members, audit);
  return { auth, groupService, chat, governance, users };
}

describe('ChatService (build spec §10)', () => {
  beforeEach(() => {
    resetMemoryStore();
  });

  it('sends and lists messages within a group', async () => {
    const { auth, groupService, chat } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'Weekend Susu', type: 'ROTATIONAL_SUSU' });

    await chat.sendMessage({
      groupId: group.id, senderId: owner.id, body: 'Hello everyone',
    });
    const messages = await chat.listMessages(group.id, owner.id);
    expect(messages).toHaveLength(1);
    expect(messages[0].body).toBe('Hello everyone');
  });

  it('rejects empty messages', async () => {
    const { auth, groupService, chat } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'G', type: 'ROTATIONAL_SUSU' });

    await expect(
      chat.sendMessage({ groupId: group.id, senderId: owner.id, body: '   ' }),
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('blocks non-members from reading or sending (spec §27)', async () => {
    const { auth, groupService, chat } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const outsider = (await auth.register({ fullName: 'B', identifier: '0551234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'G', type: 'ROTATIONAL_SUSU' });

    await expect(chat.listMessages(group.id, outsider.id)).rejects.toMatchObject({ statusCode: 403 });
    await expect(
      chat.sendMessage({ groupId: group.id, senderId: outsider.id, body: 'hi' }),
    ).rejects.toMatchObject({ statusCode: 403 });
  });

  it('announcements require a moderator-or-higher role', async () => {
    const { auth, groupService, chat } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const member = (await auth.register({ fullName: 'B', identifier: '0551234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'G', type: 'ROTATIONAL_SUSU' });
    await groupService.addMember({ actorId: owner.id, groupId: group.id, identifier: '0551234567', role: 'MEMBER' });

    await expect(
      chat.sendMessage({ groupId: group.id, senderId: member.id, body: 'ping', kind: 'ANNOUNCEMENT' }),
    ).rejects.toMatchObject({ statusCode: 403 });

    const ok = await chat.sendMessage({ groupId: group.id, senderId: owner.id, body: 'ping', kind: 'ANNOUNCEMENT' });
    expect(ok.kind).toBe('ANNOUNCEMENT');
  });
});

describe('GovernanceService (spec §20, build spec §16)', () => {
  beforeEach(() => {
    resetMemoryStore();
  });

  it('creates a proposal, votes once, and blocks duplicate votes', async () => {
    const { auth, groupService, governance } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'G', type: 'ROTATIONAL_SUSU' });

    const proposal = await governance.createProposal({
      groupId: group.id,
      userId: owner.id,
      title: 'Increase contribution to GHS 120?',
      options: ['Yes', 'No'],
      votingEnds: new Date(Date.now() + 86400000).toISOString(),
    });
    expect(proposal.status).toBe('OPEN');

    await governance.vote({ groupId: group.id, proposalId: proposal.id, userId: owner.id, option: 'Yes' });
    await expect(
      governance.vote({ groupId: group.id, proposalId: proposal.id, userId: owner.id, option: 'No' }),
    ).rejects.toMatchObject({ statusCode: 409 });
  });

  it('rejects votes after the voting period ends and invalid options', async () => {
    const { auth, groupService, governance } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'G', type: 'ROTATIONAL_SUSU' });

    const expired = await governance.createProposal({
      groupId: group.id,
      userId: owner.id,
      title: 'Expired proposal',
      options: ['Yes', 'No'],
      votingEnds: new Date(Date.now() - 1000).toISOString(),
    });
    await expect(
      governance.vote({ groupId: group.id, proposalId: expired.id, userId: owner.id, option: 'Yes' }),
    ).rejects.toMatchObject({ statusCode: 409 });

    const live = await governance.createProposal({
      groupId: group.id,
      userId: owner.id,
      title: 'Live proposal',
      options: ['Yes', 'No'],
      votingEnds: new Date(Date.now() + 86400000).toISOString(),
    });
    await expect(
      governance.vote({ groupId: group.id, proposalId: live.id, userId: owner.id, option: 'Maybe' }),
    ).rejects.toMatchObject({ statusCode: 400 });
  });

  it('non-members cannot create or vote on proposals', async () => {
    const { auth, groupService, governance } = build();
    const owner = (await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' })).user;
    const outsider = (await auth.register({ fullName: 'B', identifier: '0551234567', password: 'secret1' })).user;
    const group = await groupService.create({ ownerId: owner.id, name: 'G', type: 'ROTATIONAL_SUSU' });

    await expect(
      governance.createProposal({
        groupId: group.id, userId: outsider.id, title: 'x', options: ['Yes', 'No'],
        votingEnds: new Date(Date.now() + 86400000).toISOString(),
      }),
    ).rejects.toMatchObject({ statusCode: 403 });
  });
});
