import { randomUUID } from 'crypto';

import { GroupMember, SusuGroup, User } from '../models';
import {
  AuditRepo,
  GroupMemberRepo,
  GroupRepo,
  UserRepo,
} from '../repositories/types';
import { ApiError } from '../utils/api-error';

/**
 * Group business rules (spec §6, §14, §5). Authorization is permission-
 * driven at the service layer — the backend never trusts client claims.
 */
export class GroupService {
  constructor(
    private readonly groups: GroupRepo,
    private readonly members: GroupMemberRepo,
    private readonly users: UserRepo,
    private readonly audit: AuditRepo,
  ) {}

  async create(input: {
    ownerId: string;
    name: string;
    type: SusuGroup['type'];
    description?: string;
    currency?: string;
    rules?: Record<string, unknown>;
  }): Promise<SusuGroup> {
    const group: Omit<SusuGroup, 'created_at' | 'updated_at'> = {
      id: `grp_${randomUUID()}`,
      owner_id: input.ownerId,
      name: input.name.trim(),
      type: input.type,
      description: input.description?.trim() || null,
      currency: input.currency ?? 'GHS',
      status: 'ACTIVE',
      rules: input.rules ?? {},
    };
    const created = await this.groups.create(group);
    // The creator becomes the GROUP_OWNER member automatically.
    await this.members.add({
      group_id: created.id,
      user_id: input.ownerId,
      role: 'GROUP_OWNER',
      joined_at: new Date().toISOString(),
      permissions: [],
    });
    await this.audit.log({
      user_id: input.ownerId,
      action: 'GROUP_CREATED',
      entity_type: 'group',
      entity_id: created.id,
    });
    return created;
  }

  async listForUser(userId: string): Promise<SusuGroup[]> {
    return this.groups.listForUser(userId);
  }

  async getGroup(groupId: string, userId: string): Promise<SusuGroup> {
    const group = await this.groups.findById(groupId);
    if (!group) throw ApiError.notFound('Group not found');
    const membership = await this.members.find(groupId, userId);
    if (!membership) {
      throw ApiError.forbidden('You are not a member of this group.');
    }
    return group;
  }

  async listMembers(groupId: string, userId: string): Promise<GroupMember[]> {
    await this.requireMember(groupId, userId);
    return this.members.list(groupId);
  }

  /** Adds a member by phone/email (owner + admins only). */
  async addMember(input: {
    actorId: string;
    groupId: string;
    identifier?: string;
    role?: GroupMember['role'];
  }): Promise<GroupMember> {
    await this.requireRole(input.groupId, input.actorId, ['GROUP_OWNER', 'ADMIN']);

    let user: User | null = null;
    if (input.identifier) {
      user = await this.users.findByPhoneOrEmail(input.identifier);
    }
    if (!user) {
      // No account yet — a real backend would create an invitation.
      throw ApiError.badRequest(
        'No account found for this phone/email. Invitations arrive with the join flow.',
      );
    }
    const existing = await this.members.find(input.groupId, user.id);
    if (existing) {
      throw ApiError.conflict('This user is already a member of the group.');
    }
    const member: GroupMember = {
      group_id: input.groupId,
      user_id: user.id,
      role: input.role ?? 'MEMBER',
      joined_at: new Date().toISOString(),
      permissions: [],
    };
    await this.members.add(member);
    await this.audit.log({
      user_id: input.actorId,
      action: 'MEMBER_ADDED',
      entity_type: 'group',
      entity_id: input.groupId,
      metadata: { member_user_id: user.id, role: member.role },
    });
    return member;
  }

  async removeMember(input: {
    actorId: string;
    groupId: string;
    memberUserId: string;
  }): Promise<void> {
    await this.requireRole(input.groupId, input.actorId, ['GROUP_OWNER', 'ADMIN']);
    if (input.actorId === input.memberUserId) {
      throw ApiError.badRequest('Owners cannot remove themselves this way.');
    }
    await this.members.remove(input.groupId, input.memberUserId);
    await this.audit.log({
      user_id: input.actorId,
      action: 'MEMBER_REMOVED',
      entity_type: 'group',
      entity_id: input.groupId,
      metadata: { member_user_id: input.memberUserId },
    });
  }

  async updateMemberRole(input: {
    actorId: string;
    groupId: string;
    memberUserId: string;
    role: GroupMember['role'];
  }): Promise<void> {
    await this.requireRole(input.groupId, input.actorId, ['GROUP_OWNER']);
    await this.members.updateRole(input.groupId, input.memberUserId, input.role);
    await this.audit.log({
      user_id: input.actorId,
      action: 'MEMBER_ROLE_CHANGED',
      entity_type: 'group',
      entity_id: input.groupId,
      metadata: { member_user_id: input.memberUserId, role: input.role },
    });
  }

  // ---------------------------------------------------------------------------

  private async requireMember(groupId: string, userId: string): Promise<GroupMember> {
    const membership = await this.members.find(groupId, userId);
    if (!membership) {
      throw ApiError.forbidden('You are not a member of this group.');
    }
    return membership;
  }

  private async requireRole(
    groupId: string,
    userId: string,
    allowed: string[],
  ): Promise<GroupMember> {
    const membership = await this.requireMember(groupId, userId);
    if (!allowed.includes(membership.role)) {
      throw ApiError.forbidden('You do not have permission to do this.');
    }
    return membership;
  }
}
