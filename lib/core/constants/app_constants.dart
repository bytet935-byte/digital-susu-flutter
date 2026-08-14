/// Shared application constants that are not market-specific (see
/// `core/config/app_config.dart` for market defaults).
abstract final class AppConstants {
  /// Application-wide route prefixes and generic copy live here once they are
  /// needed by more than one feature. Navigation paths are owned by
  /// `core/routing/app_routes.dart`.
  static const String unknown = '—';

  /// Generic friendly error copy (spec §12: never show raw errors to users).
  static const String genericErrorMessage =
      'Something went wrong. Please try again.';

  /// Generic retry copy.
  static const String retry = 'Retry';

  /// Supported notification categories (spec §21). Feature screens filter by
  /// these values in Phase 4.
  static const List<String> notificationCategories = <String>[
    'contribution_reminder',
    'payment_confirmation',
    'payout',
    'missed_contribution',
    'group_announcement',
    'proposal',
    'voting_reminder',
    'transaction_alert',
    'security_alert',
  ];
}
