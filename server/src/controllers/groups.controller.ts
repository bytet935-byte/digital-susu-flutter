import { AuthenticatedRequest, requireAuth } from '../types/auth';
import { Container } from '../container';
import { asyncHandler } from '../utils/api-error';

export function groupsController(c: Container) {
  return {
    create: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as {
        name: string;
        type: 'ROTATIONAL_SUSU' | 'SAVINGS_GOAL' | 'JOINT_BUSINESS';
        description?: string;
        currency?: string;
        rules?: Record<string, unknown>;
      };
      const group = await c.groups.create({
        ownerId: userId,
        name: body.name,
        type: body.type,
        description: body.description,
        currency: body.currency,
        rules: body.rules,
      });
      res.status(201).json(group);
    }),

    list: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      res.json({ groups: await c.groups.listForUser(userId) });
    }),

    get: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const group = await c.groups.getGroup(req.params.groupId, userId);
      res.json(group);
    }),

    members: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const members = await c.groups.listMembers(req.params.groupId, userId);
      res.json({ members });
    }),

    addMember: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as { identifier?: string; role?: 'MEMBER' | 'TREASURER' | 'MODERATOR' };
      const member = await c.groups.addMember({
        actorId: userId,
        groupId: req.params.groupId,
        identifier: body.identifier,
        role: body.role,
      });
      res.status(201).json(member);
    }),

    removeMember: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      await c.groups.removeMember({
        actorId: userId,
        groupId: req.params.groupId,
        memberUserId: req.params.memberId,
      });
      res.status(204).end();
    }),

    updateMemberRole: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      await c.groups.updateMemberRole({
        actorId: userId,
        groupId: req.params.groupId,
        memberUserId: req.params.memberId,
        role: (req.body as { role: 'MEMBER' | 'TREASURER' | 'MODERATOR' | 'ADMIN' }).role,
      });
      res.json({ message: 'Role updated' });
    }),
  };
}
