import { z } from 'zod';

export const groupTypeSchema = z.enum([
  'ROTATIONAL_SUSU',
  'SAVINGS_GOAL',
  'JOINT_BUSINESS',
]);

export const createGroupSchema = z.object({
  name: z.string().trim().min(2, 'Group name is required').max(60),
  type: groupTypeSchema,
  description: z.string().trim().max(500).optional(),
  currency: z.string().length(3).default('GHS'),
  rules: z.record(z.string(), z.unknown()).optional(),
});

export const addMemberSchema = z.object({
  identifier: z
    .union([
      z.string().trim().regex(/^(\+?233|0)[2357]\d{8}$/),
      z.string().trim().email(),
    ])
    .optional(),
  role: z.enum(['MEMBER', 'TREASURER', 'MODERATOR']).default('MEMBER'),
});

export const updateMemberRoleSchema = z.object({
  role: z.enum(['MEMBER', 'TREASURER', 'MODERATOR', 'ADMIN']),
});

export const messageSchema = z.object({
  body: z.string().trim().min(1, 'Message cannot be empty').max(2000),
  kind: z.enum(['MESSAGE', 'ANNOUNCEMENT']).default('MESSAGE'),
});

export const proposalSchema = z.object({
  title: z.string().trim().min(3, 'Proposal title is required').max(120),
  description: z.string().trim().max(1000).optional(),
  options: z.array(z.string().trim().min(1)).min(2, 'At least two options are required').max(8),
  voting_ends: z.string().datetime({ offset: true }),
});

export const voteSchema = z.object({
  option: z.string().trim().min(1),
});
