import { createHash, randomUUID } from 'crypto';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';

import { env } from '../config/env';
import { PublicUser, Session, User } from '../models';
import { AuditRepo, SessionRepo, UserRepo, WalletRepo } from '../repositories/types';
import { ApiError } from '../utils/api-error';

export interface Tokens {
  accessToken: string;
  refreshToken: string;
}

export interface AuthResult {
  tokens: Tokens;
  user: PublicUser;
}

interface RefreshPayload {
  sub: string;
  sid: string;
  type: 'refresh';
}

/** In-memory OTP store (replaced by a persistence-backed store with the real
 * SMS provider). Dev code: 123456. */
const otpStore = new Map<string, { code: string; expiresAt: number }>();

export class AuthService {
  constructor(
    private readonly users: UserRepo,
    private readonly sessions: SessionRepo,
    private readonly wallets: WalletRepo,
    private readonly audit: AuditRepo,
  ) {}

  async register(input: {
    fullName: string;
    identifier: string;
    password: string;
  }): Promise<AuthResult> {
    const existing = await this.users.findByPhoneOrEmail(input.identifier);
    if (existing) {
      throw ApiError.conflict('An account already exists for this phone number or email.');
    }

    const passwordHash = await bcrypt.hash(input.password, env.bcryptRounds);
    const { phone, email } = this.splitIdentifier(input.identifier);
    const user = await this.users.create({
      full_name: input.fullName.trim(),
      phone,
      email,
      password_hash: passwordHash,
      kyc_status: 'NOT_STARTED',
      verified: false,
    });

    // Every user gets a personal wallet immediately (spec §7).
    await this.wallets.createPersonal(user.id, 'GHS');

    await this.audit.log({
      user_id: user.id,
      action: 'USER_REGISTERED',
      entity_type: 'user',
      entity_id: user.id,
    });

    const tokens = await this.createSession(user);
    return { tokens, user: toPublicUser(user) };
  }

  async login(input: { identifier: string; password: string }): Promise<AuthResult> {
    const user = await this.users.findByPhoneOrEmail(input.identifier);
    if (!user) {
      throw ApiError.unauthorized('No account found for this phone number or email.');
    }
    const matches = await bcrypt.compare(input.password, user.password_hash);
    if (!matches) {
      throw ApiError.unauthorized('Incorrect password. Please try again.');
    }
    await this.audit.log({
      user_id: user.id,
      action: 'USER_LOGIN',
      entity_type: 'user',
      entity_id: user.id,
    });
    const tokens = await this.createSession(user);
    return { tokens, user: toPublicUser(user) };
  }

  /** Registration flow: verify the 6-digit OTP (spec §10, FLOW 1). */
  async verifyOtp(input: { phone: string; code: string }): Promise<AuthResult> {
    const entry = otpStore.get(normalizePhone(input.phone));
    if (!entry || entry.expiresAt < Date.now()) {
      throw ApiError.badRequest('The code has expired. Request a new one.');
    }
    if (entry.code !== input.code) {
      throw ApiError.badRequest('Invalid verification code.');
    }
    const user = await this.users.findByPhoneOrEmail(input.phone);
    if (!user) {
      throw ApiError.notFound('Account not found. Please register first.');
    }
    otpStore.delete(normalizePhone(input.phone));
    await this.users.updateProfile(user.id, {});
    await this.audit.log({
      user_id: user.id,
      action: 'USER_VERIFIED',
      entity_type: 'user',
      entity_id: user.id,
    });
    const tokens = await this.createSession(user);
    return { tokens, user: toPublicUser(user) };
  }

  /** Sends an OTP (dev: stores 123456; production: SMS provider). */
  async requestOtp(input: { phone: string }): Promise<void> {
    otpStore.set(normalizePhone(input.phone), {
      code: '123456',
      expiresAt: Date.now() + 10 * 60 * 1000,
    });
  }

  async refresh(refreshToken: string): Promise<Tokens> {
    let payload: RefreshPayload;
    try {
      payload = jwt.verify(refreshToken, env.jwtRefreshSecret) as RefreshPayload;
    } catch {
      throw new ApiError(401, 'TOKEN_EXPIRED', 'Your session has expired. Please log in again.');
    }
    if (payload.type !== 'refresh') {
      throw ApiError.unauthorized('Invalid refresh token.');
    }
    const session = await this.sessions.findActiveById(payload.sid);
    if (!session) {
      throw new ApiError(401, 'TOKEN_EXPIRED', 'Your session has expired. Please log in again.');
    }
    const hash = hashToken(refreshToken);
    if (session.refresh_token_hash !== hash) {
      throw ApiError.unauthorized('Invalid refresh token.');
    }
    const user = await this.users.findById(payload.sub);
    if (!user) {
      throw ApiError.unauthorized('Account no longer exists.');
    }
    // Rotate: revoke the old session, issue a fresh pair.
    await this.sessions.revoke(session.id);
    return this.createSession(user);
  }

  async logout(userId: string, sessionId: string): Promise<void> {
    await this.sessions.revoke(sessionId);
    await this.audit.log({
      user_id: userId,
      action: 'USER_LOGOUT',
      entity_type: 'user',
      entity_id: userId,
    });
  }

  async me(userId: string): Promise<PublicUser> {
    const user = await this.users.findById(userId);
    if (!user) throw ApiError.notFound('Account not found');
    return toPublicUser(user);
  }

  async forgotPassword(identifier: string): Promise<void> {
    const user = await this.users.findByPhoneOrEmail(identifier);
    if (!user) {
      // Do not reveal whether the account exists (spec §27).
      return;
    }
    await this.requestOtp({ phone: user.phone });
  }

  async resetPassword(input: { code: string; newPassword: string; identifier: string }): Promise<void> {
    const entry = otpStore.get(normalizePhone(input.identifier));
    if (!entry || entry.code !== input.code || entry.expiresAt < Date.now()) {
      throw ApiError.badRequest('Invalid or expired reset code.');
    }
    const user = await this.users.findByPhoneOrEmail(input.identifier);
    if (!user) throw ApiError.notFound('Account not found');
    const passwordHash = await bcrypt.hash(input.newPassword, env.bcryptRounds);
    await this.users.updatePassword(user.id, passwordHash);
    otpStore.delete(normalizePhone(input.identifier));
    await this.audit.log({
      user_id: user.id,
      action: 'PASSWORD_RESET',
      entity_type: 'user',
      entity_id: user.id,
    });
  }

  // ---------------------------------------------------------------------------

  private async createSession(user: User): Promise<Tokens> {
    const sessionId = `ses_${randomUUID()}`;
    const accessToken = jwt.sign(
      { sub: user.id, sid: sessionId, type: 'access' },
      env.jwtAccessSecret,
      { expiresIn: env.jwtAccessExpiresIn as jwt.SignOptions['expiresIn'] },
    );
    const refreshToken = jwt.sign(
      { sub: user.id, sid: sessionId, type: 'refresh' },
      env.jwtRefreshSecret,
      { expiresIn: env.jwtRefreshExpiresIn as jwt.SignOptions['expiresIn'] },
    );
    const session: Omit<Session, 'created_at'> = {
      id: sessionId,
      user_id: user.id,
      refresh_token_hash: hashToken(refreshToken),
      expires_at: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
      revoked_at: null,
    };
    await this.sessions.create(session);
    return { accessToken, refreshToken };
  }

  private splitIdentifier(identifier: string): { phone: string; email: string | null } {
    const trimmed = identifier.trim();
    if (trimmed.includes('@')) {
      return { phone: '', email: trimmed.toLowerCase() };
    }
    return { phone: normalizePhone(trimmed), email: null };
  }
}

export function toPublicUser(user: User): PublicUser {
  const { password_hash: _hash, ...rest } = user;
  return rest;
}

function normalizePhone(phone: string): string {
  let digits = phone.replace(/[\s\-()]/g, '');
  if (digits.startsWith('+')) digits = digits.slice(1);
  if (digits.startsWith('0')) digits = `233${digits.slice(1)}`;
  return digits;
}

function hashToken(token: string): string {
  return createHash('sha256').update(token).digest('hex');
}
