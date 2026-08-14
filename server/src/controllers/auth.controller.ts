import { AuthenticatedRequest, requireAuth } from '../types/auth';
import { Container } from '../container';
import { asyncHandler } from '../utils/api-error';

export function authController(c: Container) {
  return {
    register: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const body = req.body as { full_name: string; identifier: string; password: string };
      const result = await c.auth.register({
        fullName: body.full_name,
        identifier: body.identifier,
        password: body.password,
      });
      res.status(201).json({
        access_token: result.tokens.accessToken,
        refresh_token: result.tokens.refreshToken,
        user: result.user,
      });
    }),

    login: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const body = req.body as { identifier: string; password: string };
      const result = await c.auth.login(body);
      res.json({ access_token: result.tokens.accessToken, refresh_token: result.tokens.refreshToken, user: result.user });
    }),

    requestOtp: asyncHandler(async (req: AuthenticatedRequest, res) => {
      await c.auth.requestOtp({ phone: (req.body as { phone: string }).phone });
      res.json({ message: 'Verification code sent' });
    }),

    verifyOtp: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const body = req.body as { phone: string; code: string };
      const result = await c.auth.verifyOtp(body);
      res.json({ access_token: result.tokens.accessToken, refresh_token: result.tokens.refreshToken, user: result.user });
    }),

    refresh: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const tokens = await c.auth.refresh((req.body as { refresh_token: string }).refresh_token);
      res.json(tokens);
    }),

    logout: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId, sessionId } = requireAuth(req);
      await c.auth.logout(userId, sessionId);
      res.status(204).end();
    }),

    me: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const { userId } = requireAuth(req);
      res.json(await c.auth.me(userId));
    }),

    forgotPassword: asyncHandler(async (req: AuthenticatedRequest, res) => {
      await c.auth.forgotPassword((req.body as { identifier: string }).identifier);
      res.json({ message: 'If the account exists, a reset code has been sent.' });
    }),

    resetPassword: asyncHandler(async (req: AuthenticatedRequest, res) => {
      const body = req.body as { code: string; new_password: string; identifier?: string };
      const identifier = body.identifier ?? '';
      await c.auth.resetPassword({ code: body.code, newPassword: body.new_password, identifier });
      res.json({ message: 'Password updated. Please log in.' });
    }),
  };
}
