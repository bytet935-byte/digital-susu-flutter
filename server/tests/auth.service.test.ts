import { beforeEach, describe, expect, it } from 'vitest';

import { resetMemoryStore } from '../src/repositories/memory.repos';
import { AuthService } from '../src/services/auth.service';
import {
  MemoryAuditRepo,
  MemorySessionRepo,
  MemoryUserRepo,
  MemoryWalletRepo,
} from '../src/repositories/memory.repos';
import { ApiError } from '../src/utils/api-error';

function buildAuthService(): AuthService {
  return new AuthService(
    new MemoryUserRepo(),
    new MemorySessionRepo(),
    new MemoryWalletRepo(),
    new MemoryAuditRepo(),
  );
}

describe('AuthService (spec §10, FLOW 1)', () => {
  beforeEach(() => {
    resetMemoryStore();
  });

  it('registers a user, creates a personal wallet and returns tokens', async () => {
    const auth = buildAuthService();
    const result = await auth.register({
      fullName: 'Kwame Owusu',
      identifier: '0241234567',
      password: 'secret1',
    });

    expect(result.user.full_name).toBe('Kwame Owusu');
    expect(result.user.phone).toBe('233241234567'); // stored in E.164 form
    expect(result.tokens.accessToken).toBeTruthy();
    expect(result.tokens.refreshToken).toBeTruthy();
    // The public user must never expose the password hash.
    expect(JSON.stringify(result.user)).not.toContain('password');
  });

  it('rejects duplicate registrations (same phone)', async () => {
    const auth = buildAuthService();
    await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' });
    await expect(
      auth.register({ fullName: 'B', identifier: '0241234567', password: 'secret1' }),
    ).rejects.toBeInstanceOf(ApiError);
  });

  it('rejects a wrong password', async () => {
    const auth = buildAuthService();
    await auth.register({ fullName: 'A', identifier: '0241234567', password: 'secret1' });
    await expect(
      auth.login({ identifier: '0241234567', password: 'wrong-password' }),
    ).rejects.toMatchObject({ statusCode: 401 });
  });

  it('refreshes by rotating the session (old refresh token dies)', async () => {
    const auth = buildAuthService();
    const { tokens } = await auth.register({
      fullName: 'A', identifier: '0241234567', password: 'secret1',
    });

    const rotated = await auth.refresh(tokens.refreshToken);
    expect(rotated.accessToken).toBeTruthy();
    expect(rotated.refreshToken).not.toBe(tokens.refreshToken);

    // The old refresh token must no longer work.
    await expect(auth.refresh(tokens.refreshToken)).rejects.toMatchObject({
      statusCode: 401,
    });
  });

  it('logout revokes the session so refresh fails afterwards', async () => {
    const auth = buildAuthService();
    const { tokens, user } = await auth.register({
      fullName: 'A', identifier: '0241234567', password: 'secret1',
    });

    const decoded = JSON.parse(
      Buffer.from(tokens.accessToken.split('.')[1], 'base64url').toString(),
    ) as { sid: string };
    await auth.logout(user.id, decoded.sid);

    await expect(auth.refresh(tokens.refreshToken)).rejects.toMatchObject({
      statusCode: 401,
    });
  });

  it('verifies registration OTP and requests codes (dev code 123456)', async () => {
    const auth = buildAuthService();
    await auth.register({ fullName: 'A', identifier: '0551234567', password: 'secret1' });
    await auth.requestOtp({ phone: '0551234567' });

    const verified = await auth.verifyOtp({ phone: '0551234567', code: '123456' });
    expect(verified.user.phone).toBe('233551234567');

    await expect(
      auth.verifyOtp({ phone: '0551234567', code: '000000' }),
    ).rejects.toMatchObject({ statusCode: 400 });
  });
});
