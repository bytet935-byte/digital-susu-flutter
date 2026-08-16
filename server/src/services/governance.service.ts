import { Proposal } from '../models';
import {
  AuditRepo,
  GroupMemberRepo,
  ProposalRepo,
} from '../repositories/types';
import { ApiError } from '../utils/api-error';

/**
 * Governance (spec §20, build spec §16): proposals and single-vote voting.
 * One vote per user per proposal is enforced structurally (PK) and in the
 * service; votes are only accepted while the proposal is OPEN and the user
 * is a member.
 */
export class GovernanceService {
  constructor(
    private readonly proposals: ProposalRepo,
    private readonly members: GroupMemberRepo,
    private readonly audit: AuditRepo,
  ) {}

  async createProposal(input: {
    groupId: string;
    userId: string;
    title: string;
    description?: string;
    options: string[];
    votingEnds: string;
  }): Promise<Proposal> {
    await this.requireMember(input.groupId, input.userId);
    if (!input.title.trim()) {
      throw ApiError.badRequest('Proposal title is required.');
    }
    if (input.options.length < 2) {
      throw ApiError.badRequest('A proposal needs at least two options.');
    }
    const proposal = await this.proposals.create({
      group_id: input.groupId,
      created_by: input.userId,
      title: input.title.trim(),
      description: input.description?.trim() || null,
      options: input.options,
      voting_ends: input.votingEnds,
      status: 'OPEN',
      result: null,
    });
    await this.audit.log({
      user_id: input.userId,
      action: 'PROPOSAL_CREATED',
      entity_type: 'group',
      entity_id: input.groupId,
      metadata: { proposal_id: proposal.id },
    });
    return proposal;
  }

  async listProposals(groupId: string, userId: string): Promise<Proposal[]> {
    await this.requireMember(groupId, userId);
    return this.proposals.listForGroup(groupId);
  }

  async vote(input: {
    groupId: string;
    proposalId: string;
    userId: string;
    option: string;
  }): Promise<void> {
    await this.requireMember(input.groupId, input.userId);
    const proposal = await this.proposals.findById(input.proposalId);
    if (!proposal || proposal.group_id !== input.groupId) {
      throw ApiError.notFound('Proposal not found.');
    }
    if (proposal.status !== 'OPEN') {
      throw ApiError.conflict('Voting has closed for this proposal.');
    }
    if (new Date(proposal.voting_ends) < new Date()) {
      throw ApiError.conflict('The voting period has ended.');
    }
    if (!proposal.options.includes(input.option)) {
      throw ApiError.badRequest('Invalid option for this proposal.');
    }
    const existing = await this.proposals.findVote(input.proposalId, input.userId);
    if (existing) {
      throw ApiError.conflict('You have already voted on this proposal.');
    }
    await this.proposals.vote({
      proposal_id: input.proposalId,
      user_id: input.userId,
      option: input.option,
      created_at: new Date().toISOString(),
    });
    await this.audit.log({
      user_id: input.userId,
      action: 'PROPOSAL_VOTED',
      entity_type: 'proposal',
      entity_id: input.proposalId,
    });
  }

  private async requireMember(groupId: string, userId: string) {
    const membership = await this.members.find(groupId, userId);
    if (!membership) {
      throw ApiError.forbidden('You are not a member of this group.');
    }
    return membership;
  }
}
