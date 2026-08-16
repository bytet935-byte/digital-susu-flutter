import { AuthenticatedRequest, requireAuth } from '../types/auth';
import { Container } from '../container';
import { asyncHandler } from '../utils/api-error';

export function chatController(c: Container) {
  return {
    list: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const messages = await c.chat.listMessages(req.params.groupId, userId);
      res.json({ messages });
    }),

    send: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as { body: string; kind?: 'MESSAGE' | 'ANNOUNCEMENT' };
      const message = await c.chat.sendMessage({
        groupId: req.params.groupId,
        senderId: userId,
        body: body.body,
        kind: body.kind,
      });
      res.status(201).json(message);
    }),
  };
}

export function notificationsController(c: Container) {
  return {
    list: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      res.json({
        notifications: await c.notifications.listForUser(userId),
        unread_count: await c.notifications.unreadCount(userId),
      });
    }),

    markRead: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      await c.notifications.markRead(req.params.notificationId, userId);
      res.json({ message: 'Marked as read' });
    }),

    markAllRead: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      await c.notifications.markAllRead(userId);
      res.json({ message: 'All notifications marked as read' });
    }),
  };
}

export function governanceController(c: Container) {
  return {
    create: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as {
        title: string;
        description?: string;
        options: string[];
        voting_ends: string;
      };
      const proposal = await c.governance.createProposal({
        groupId: req.params.groupId,
        userId,
        title: body.title,
        description: body.description,
        options: body.options,
        votingEnds: body.voting_ends,
      });
      res.status(201).json(proposal);
    }),

    list: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      res.json({
        proposals: await c.governance.listProposals(req.params.groupId, userId),
      });
    }),

    vote: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      await c.governance.vote({
        groupId: req.params.groupId,
        proposalId: req.params.proposalId,
        userId,
        option: (req.body as { option: string }).option,
      });
      res.status(201).json({ message: 'Vote recorded' });
    }),
  };
}
