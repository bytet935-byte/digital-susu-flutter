import { z } from 'zod';

/** Ghanaian phone: 0XXXXXXXXX or +233XXXXXXXXX (spec §2). */
export const phoneSchema = z
  .string()
  .trim()
  .regex(
    /^(\+?233|0)[2357]\d{8}$/,
    'Enter a valid Ghanaian phone number',
  );

export const emailSchema = z.string().trim().email().optional();

const passwordSchema = z
  .string()
  .min(6, 'Password must be at least 6 characters')
  .max(128);

/** Registration: only necessary information (spec §5). */
export const registerSchema = z.object({
  full_name: z.string().trim().min(2, 'Enter your full name').max(60),
  identifier: z.union([phoneSchema, z.string().trim().email()]),
  password: passwordSchema,
});

export const loginSchema = z.object({
  identifier: z.string().trim().min(1, 'Enter your email or phone number'),
  password: z.string().min(1, 'Enter your password'),
});

export const otpSchema = z.object({
  phone: z.string().trim().min(1),
  code: z.string().regex(/^\d{6}$/, 'The code must be exactly 6 digits'),
});

export const refreshSchema = z.object({
  refresh_token: z.string().min(10),
});

export const forgotPasswordSchema = z.object({
  identifier: z.string().trim().min(1),
});

export const resetPasswordSchema = z.object({
  code: z.string().regex(/^\d{6}$/, 'The code must be exactly 6 digits'),
  new_password: passwordSchema,
});
