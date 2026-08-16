/**
 * Core domain models (spec §22, §24). These are the data contracts between
 * services and repositories. PostgreSQL types mirror database/schema.sql.
 */

export type Role =
  | 'MEMBER'
  | 'GROUP_OWNER'
  | 'ADMIN'
  | 'TREASURER'
  | 'MODERATOR'
  | 'SYSTEM_ADMIN';

export type GroupType = 'ROTATIONAL_SUSU' | 'SAVINGS_GOAL' | 'JOINT_BUSINESS';
export type GroupStatus = 'ACTIVE' | 'UPCOMING' | 'COMPLETED' | 'PENDING' | 'PAUSED';

export interface User {
  id: string;
  full_name: string;
  phone: string;
  email?: string | null;
  password_hash: string;
  kyc_status: 'NOT_STARTED' | 'PENDING' | 'VERIFIED' | 'REJECTED' | 'EXPIRED';
  verified: boolean;
  created_at: string;
  updated_at: string;
}

/** Public user shape — never includes the password hash. */
export type PublicUser = Omit<User, 'password_hash'>;

export interface Session {
  id: string;
  user_id: string;
  refresh_token_hash: string;
  expires_at: string;
  created_at: string;
  revoked_at?: string | null;
}

export interface SusuGroup {
  id: string;
  owner_id: string;
  name: string;
  type: GroupType;
  description?: string | null;
  currency: string;
  status: GroupStatus;
  rules: Record<string, unknown>;
  created_at: string;
  updated_at: string;
}

export interface GroupMember {
  group_id: string;
  user_id: string;
  role: Role;
  joined_at: string;
  permissions: string[];
}

export interface Wallet {
  id: string;
  owner_user_id?: string | null;
  group_id?: string | null;
  balance_minor: number;
  currency: string;
  created_at: string;
  updated_at: string;
}

export type TransactionStatus = 'SUCCESSFUL' | 'PENDING' | 'FAILED' | 'REVERSED';

export interface Transaction {
  id: string;
  user_id: string;
  group_id?: string | null;
  wallet_id: string;
  amount_minor: number;
  currency: string;
  type: string; // CONTRIBUTION | PAYOUT | DEPOSIT | WITHDRAWAL | ...
  status: TransactionStatus;
  reference: string;
  idempotency_key?: string | null;
  payment_method?: string | null;
  metadata?: Record<string, unknown> | null;
  created_at: string;
  created_by: string;
  approved_by?: string | null;
}

export interface AuditLog {
  id: string;
  user_id?: string | null;
  action: string;
  entity_type?: string | null;
  entity_id?: string | null;
  metadata?: Record<string, unknown> | null;
  created_at: string;
}

export interface Notification {
  id: string;
  user_id: string;
  title: string;
  body: string;
  category: string;
  read: boolean;
  created_at: string;
}

export interface GroupMessage {
  id: string;
  group_id: string;
  sender_id: string;
  body: string;
  kind: 'MESSAGE' | 'ANNOUNCEMENT';
  pinned: boolean;
  created_at: string;
}

export interface Proposal {
  id: string;
  group_id: string;
  created_by: string;
  title: string;
  description?: string | null;
  options: string[];
  voting_ends: string;
  status: 'OPEN' | 'APPROVED' | 'REJECTED' | 'EXPIRED';
  result?: string | null;
  created_at: string;
}

export interface ProposalVote {
  proposal_id: string;
  user_id: string;
  option: string;
  created_at: string;
}
