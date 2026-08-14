import { Router } from 'express';

import { Container } from '../container';
import { authMiddleware } from '../middleware/auth.middleware';
import { authRateLimit, globalRateLimit } from '../middleware/rate-limit.middleware';
import { validateBody } from '../middleware/validate.middleware';
import {
  forgotPasswordSchema,
  loginSchema,
  otpSchema,
  refreshSchema,
  registerSchema,
  resetPasswordSchema,
} from '../validators/auth.schemas';
import { addMemberSchema, createGroupSchema, updateMemberRoleSchema } from '../validators/group.schemas';
import { authController } from '../controllers/auth.controller';
import { groupsController } from '../controllers/groups.controller';
import { transactionsController } from '../controllers/transactions.controller';
import { walletsController } from '../controllers/wallets.controller';

/**
 * Route registration (spec §23): public auth routes first, then the
 * authenticated API surface behind authMiddleware.
 */
export function buildRouter(c: Container): Router {
  const router = Router();
  const auth = authController(c);
  const groups = groupsController(c);
  const wallets = walletsController(c);
  const transactions = transactionsController(c);

  // Health
  router.get('/health', (_req, res) => {
    res.json({ status: 'ok', mode: c.mode, time: new Date().toISOString() });
  });

  // Public auth routes (stricter rate limiting — spec §12, §27)
  router.post('/auth/register', authRateLimit, validateBody(registerSchema), auth.register);
  router.post('/auth/login', authRateLimit, validateBody(loginSchema), auth.login);
  router.post('/auth/request-otp', authRateLimit, validateBody(otpSchema), auth.requestOtp);
  router.post('/auth/verify-otp', authRateLimit, validateBody(otpSchema), auth.verifyOtp);
  router.post('/auth/refresh', authRateLimit, validateBody(refreshSchema), auth.refresh);
  router.post('/auth/forgot-password', authRateLimit, validateBody(forgotPasswordSchema), auth.forgotPassword);
  router.post('/auth/reset-password', authRateLimit, validateBody(resetPasswordSchema), auth.resetPassword);

  // Authenticated routes (per-route middleware so unknown paths 404 instead
  // of 401 — the app-level notFoundHandler owns unmatched routes).
  router.post('/auth/logout', authMiddleware, auth.logout);
  router.get('/users/me', authMiddleware, auth.me);

  router.post('/groups', authMiddleware, validateBody(createGroupSchema), groups.create);
  router.get('/groups', authMiddleware, groups.list);
  router.get('/groups/:groupId', authMiddleware, groups.get);
  router.get('/groups/:groupId/members', authMiddleware, groups.members);
  router.post('/groups/:groupId/members', authMiddleware, validateBody(addMemberSchema), groups.addMember);
  router.delete('/groups/:groupId/members/:memberId', authMiddleware, groups.removeMember);
  router.patch('/groups/:groupId/members/:memberId', authMiddleware, validateBody(updateMemberRoleSchema), groups.updateMemberRole);

  router.get('/wallet', authMiddleware, wallets.personal);
  router.post('/wallet/top-up', authMiddleware, wallets.topUp);
  router.post('/wallet/withdraw', authMiddleware, wallets.withdraw);
  router.get('/groups/:groupId/wallet', authMiddleware, wallets.group);
  router.post('/groups/:groupId/contributions', authMiddleware, wallets.contribute);

  router.get('/transactions', authMiddleware, transactions.list);

  return router;
}

export { globalRateLimit };
