/// REST endpoint paths — mirrors `server/src/routes/index.ts` where the
/// backend implements the route. Endpoints marked *pending* exist in the
/// client contract for features whose server routes land in a later phase;
/// in mock mode (`USE_MOCK_DATA=true`) they are never hit.
abstract final class ApiEndpoints {
  // ---------------------------------------------------------------------------
  // Public auth (spec §10)
  // ---------------------------------------------------------------------------
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String requestOtp = '/auth/request-otp';
  static const String resendOtp = '/auth/request-otp';
  static const String verifyOtp = '/auth/verify-otp';
  static const String refresh = '/auth/refresh';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';

  // ---------------------------------------------------------------------------
  // Authenticated
  // ---------------------------------------------------------------------------
  static const String logout = '/auth/logout';
  static const String me = '/users/me';

  // Wallet
  static const String wallet = '/wallet';
  static const String walletTopUp = '/wallet/top-up';
  static const String walletWithdraw = '/wallet/withdraw';

  /// Dashboard summary — served by the personal wallet endpoint until a
  /// dedicated `/dashboard` endpoint lands.
  static const String dashboard = wallet;

  // Groups
  static const String groups = '/groups';
  static String group(String groupId) => '/groups/$groupId';
  static String groupMembers(String groupId) => '/groups/$groupId/members';
  static String groupWallet(String groupId) => '/groups/$groupId/wallet';
  static String groupContributions(String groupId) =>
      '/groups/$groupId/contributions';

  /// Group chat messages — server route pending (Phase 5).
  static String groupMessages(String groupId) => '/groups/$groupId/messages';

  // Transactions
  static const String transactions = '/transactions';

  // Notifications — server routes pending (Phase 4+).
  static const String notifications = '/notifications';
  static String notification(String notificationId) =>
      '/notifications/$notificationId';
  static const String notificationsReadAll = '/notifications/read-all';
}
