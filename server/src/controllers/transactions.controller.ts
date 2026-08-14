import { AuthenticatedRequest, requireAuth } from '../types/auth';
import { Container } from '../container';
import { asyncHandler } from '../utils/api-error';

export function transactionsController(c: Container) {
  return {
    list: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const type = typeof req.query.type === 'string' ? req.query.type : undefined;
      const status = typeof req.query.status === 'string' ? req.query.status : undefined;
      const transactions = await c.transactions.listForUser(userId, { type, status });
      res.json({ transactions });
    }),
  };
}
