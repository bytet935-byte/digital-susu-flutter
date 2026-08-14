import { AuthenticatedRequest, requireAuth } from '../types/auth';
import { Container } from '../container';
import { asyncHandler } from '../utils/api-error';

export function walletsController(c: Container) {
  return {
    personal: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const wallet = await c.wallets.getPersonalWallet(userId);
      res.json({ wallet: { ...wallet, balance: wallet.balance_minor } });
    }),

    group: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const wallet = await c.wallets.getGroupWallet(req.params.groupId, userId);
      res.json({ wallet: { ...wallet, balance: wallet.balance_minor } });
    }),

    topUp: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as { amount_minor: number; payment_method: string; idempotency_key: string };
      const transaction = await c.wallets.topUp({
        userId,
        amountMinor: body.amount_minor,
        paymentMethod: body.payment_method,
        idempotencyKey: body.idempotency_key,
      });
      res.status(201).json(transaction);
    }),

    withdraw: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as { amount_minor: number; payment_method: string; idempotency_key: string };
      const transaction = await c.wallets.withdraw({
        userId,
        amountMinor: body.amount_minor,
        paymentMethod: body.payment_method,
        idempotencyKey: body.idempotency_key,
      });
      res.status(201).json(transaction);
    }),

    contribute: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      const body = req.body as { amount_minor: number; payment_method: string; idempotency_key: string };
      const transaction = await c.wallets.contribute({
        userId,
        groupId: req.params.groupId,
        amountMinor: body.amount_minor,
        paymentMethod: body.payment_method,
        idempotencyKey: body.idempotency_key,
      });
      res.status(201).json(transaction);
    }),
  };
}
