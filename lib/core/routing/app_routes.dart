/// Centralized route paths (spec §30).
///
/// Feature screens are attached to these paths in `app_router.dart` as each
/// phase lands. Path constants are defined up front so navigation calls and
/// redirect logic never depend on raw string literals.
abstract final class AppRoutes {
  // Brand entry
  static const String splash = '/';

  // Authentication (Phase 3 wires the full screens)
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';

  // Core app
  static const String dashboard = '/dashboard';
  static const String groups = '/groups';
  static const String groupDetailsTemplate = '/groups/:groupId';

  /// Builds a group details path for a concrete group id.
  static String groupDetails(String groupId) => '/groups/$groupId';

  static const String contributions = '/contributions';
  static const String savings = '/savings';
  static const String rotationalSusu = '/rotational-susu';
  static const String jointBusiness = '/joint-business';
  static const String wallet = '/wallet';
  static const String payments = '/payments';
  static const String transactions = '/transactions';
  static const String notifications = '/notifications';
  static const String chat = '/chat';
  static const String voting = '/voting';
  static const String reports = '/reports';
  static const String profile = '/profile';
  static const String profileEdit = '/profile/edit';
  static const String settings = '/settings';
  static const String kyc = '/kyc';

  /// Routes reachable without an authenticated session (spec §10, §30).
  static const List<String> publicRoutes = <String>[
    splash,
    login,
    register,
    otp,
    forgotPassword,
    resetPassword,
  ];
}
