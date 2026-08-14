/// Centralised API endpoint paths (spec §11).
///
/// Paths are relative to [AppEnvironment.apiBaseUrl] (which already includes
/// the `/v1` segment). Grouped by feature; parameterised paths are functions.
abstract final class ApiEndpoints {
  // -------------------------------------------------------------------------
  // Authentication & users
  // -------------------------------------------------------------------------
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String refreshToken = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String logout = '/auth/logout';
  static const String me = '/users/me';
  static const String myPermissions = '/users/me/permissions';

  // -------------------------------------------------------------------------
  // Dashboard (permission-filtered, spec §13)
  // -------------------------------------------------------------------------
  static const String dashboard = '/dashboard';

  // -------------------------------------------------------------------------
  // Groups & members
  // -------------------------------------------------------------------------
  static const String groups = '/groups';
  static String group(String groupId) => '/groups/$groupId';
  static String groupMembers(String groupId) => '/groups/$groupId/members';
  static String groupMember(String groupId, String memberId) =>
      '/groups/$groupId/members/$memberId';
  static String groupInvites(String groupId) => '/groups/$groupId/invites';
  static String groupAnnouncements(String groupId) =>
      '/groups/$groupId/announcements';
  static String groupAudit(String groupId) => '/groups/$groupId/audit';

  // -------------------------------------------------------------------------
  // Contributions
  // -------------------------------------------------------------------------
  static String contributions(String groupId) =>
      '/groups/$groupId/contributions';
  static String contribution(String groupId, String contributionId) =>
      '/groups/$groupId/contributions/$contributionId';

  // -------------------------------------------------------------------------
  // Wallets (spec §7 — personal and group wallets are separate)
  // -------------------------------------------------------------------------
  static const String wallet = '/wallet';
  static const String walletTransactions = '/wallet/transactions';
  static String groupWallet(String groupId) => '/groups/$groupId/wallet';
  static String groupWalletTransactions(String groupId) =>
      '/groups/$groupId/wallet/transactions';

  // -------------------------------------------------------------------------
  // Payments (provider-independent, spec §9)
  // -------------------------------------------------------------------------
  static const String payments = '/payments';
  static String payment(String paymentId) => '/payments/$paymentId';
  static const String paymentMethods = '/payments/methods';

  // -------------------------------------------------------------------------
  // Transactions
  // -------------------------------------------------------------------------
  static const String transactions = '/transactions';
  static String transaction(String transactionId) => '/transactions/$transactionId';

  // -------------------------------------------------------------------------
  // Notifications
  // -------------------------------------------------------------------------
  static const String notifications = '/notifications';
  static String notification(String notificationId) =>
      '/notifications/$notificationId';
  static const String notificationsReadAll = '/notifications/read-all';

  // -------------------------------------------------------------------------
  // Chat
  // -------------------------------------------------------------------------
  static String groupMessages(String groupId) => '/groups/$groupId/messages';
  static String reportMessage(String groupId, String messageId) =>
      '/groups/$groupId/messages/$messageId/report';

  // -------------------------------------------------------------------------
  // Voting / proposals
  // -------------------------------------------------------------------------
  static String proposals(String groupId) => '/groups/$groupId/proposals';
  static String proposal(String groupId, String proposalId) =>
      '/groups/$groupId/proposals/$proposalId';
  static String proposalVote(String groupId, String proposalId) =>
      '/groups/$groupId/proposals/$proposalId/vote';

  // -------------------------------------------------------------------------
  // Reports (spec §24)
  // -------------------------------------------------------------------------
  static const String personalStatement = '/reports/personal-statement';
  static String groupReport(String groupId, String reportType) =>
      '/groups/$groupId/reports/$reportType';

  // -------------------------------------------------------------------------
  // KYC (spec §23)
  // -------------------------------------------------------------------------
  static const String kyc = '/kyc';
  static const String kycStatus = '/kyc/status';

  // -------------------------------------------------------------------------
  // Susu systems (Phase 7)
  // -------------------------------------------------------------------------
  static String susuSchedules(String groupId) =>
      '/groups/$groupId/susu-schedules';
  static String savingsGoals(String groupId) =>
      '/groups/$groupId/savings-goals';
  static String businessLedger(String groupId) =>
      '/groups/$groupId/business';
}
