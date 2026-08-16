import { Notification } from '../models';
import { NotificationRepo } from '../repositories/types';

/**
 * Notification center (build spec §15, spec §21): list, unread count,
 * read/unread. All reads are scoped to the authenticated user.
 */
export class NotificationService {
  constructor(private readonly notifications: NotificationRepo) {}

  listForUser(userId: string): Promise<Notification[]> {
    return this.notifications.listForUser(userId);
  }

  async unreadCount(userId: string): Promise<number> {
    return this.notifications.unreadCount(userId);
  }

  async markRead(notificationId: string, userId: string): Promise<void> {
    await this.notifications.markRead(notificationId, userId);
  }

  async markAllRead(userId: string): Promise<void> {
    await this.notifications.markAllRead(userId);
  }
}
