import { GroupMessage } from '../models';
import {
  AuditRepo,
  GroupMemberRepo,
  MessageRepo,
} from '../repositories/types';
import { ApiError } from '../utils/api-error';

/**
 * Group chat business rules (build spec §10): messaging is membership-gated;
 * announcements require a moderator-or-higher role. Moderation actions
 * (report/delete) land with Phase 8.
 */
export class ChatService {
  constructor(
    private readonly messages: MessageRepo,
    private readonly members: GroupMemberRepo,
    private readonly audit: AuditRepo,
  ) {}

  async listMessages(groupId: string, userId: string): Promise<GroupMessage[]> {
    await this.requireMember(groupId, userId);
    return this.messages.listForGroup(groupId);
  }

  async sendMessage(input: {
    groupId: string;
    senderId: string;
    body: string;
    kind?: 'MESSAGE' | 'ANNOUNCEMENT';
  }): Promise<GroupMessage> {
    const body = input.body.trim();
    if (!body) {
      throw ApiError.badRequest('Message cannot be empty.');
    }
    if (body.length > 2000) {
      throw ApiError.badRequest('Message is too long (max 2000 characters).');
    }
    await this.requireMember(input.groupId, input.senderId);

    const kind = input.kind ?? 'MESSAGE';
    if (kind === 'ANNOUNCEMENT') {
      await this.requireRole(input.groupId, input.senderId, [
        'GROUP_OWNER',
        'ADMIN',
        'MODERATOR',
      ]);
    }

    const message = await this.messages.create({
      group_id: input.groupId,
      sender_id: input.senderId,
      body,
      kind,
      pinned: false,
    });
    await this.audit.log({
      user_id: input.senderId,
      action: kind === 'ANNOUNCEMENT' ? 'GROUP_ANNOUNCED' : 'GROUP_MESSAGE_SENT',
      entity_type: 'group',
      entity_id: input.groupId,
      metadata: { message_id: message.id },
    });
    return message;
  }

  private async requireMember(groupId: string, userId: string) {
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
  ) {
    const membership = await this.requireMember(groupId, userId);
    if (!allowed.includes(membership.role)) {
      throw ApiError.forbidden('You do not have permission to do this.');
    }
    return membership;
  }
}
