/// Application-level configuration.
///
/// Ghana-first defaults (spec §2) are centralised here so that no widget or
/// feature hard-codes country-specific values. Future markets are supported by
/// introducing a per-market `AppConfig` instance without touching business
/// logic.
///
/// Compile-time flags (USE_MOCK_DATA / API_BASE_URL) live in [AppEnvironment]
/// (see `environment.dart`).
abstract final class AppConfig {
  // ---------------------------------------------------------------------------
  // App identity
  // ---------------------------------------------------------------------------

  /// Public application name.
  static const String appName = 'Digital Susu';

  /// Version shown in-app. Source of truth: pubspec `version`.
  static const String appVersion = '2.0.0';

  // ---------------------------------------------------------------------------
  // Market defaults — Ghana (spec §2)
  // ---------------------------------------------------------------------------

  /// ISO 3166-1 alpha-2 country code.
  static const String countryCode = 'GH';

  /// Human-readable country name.
  static const String countryName = 'Ghana';

  /// ISO 4217 currency code.
  static const String currencyCode = 'GHS';

  /// Display currency symbol.
  static const String currencySymbol = 'GH₵';

  /// Smallest currency unit (GHS pesewas).
  static const int currencyMinorUnit = 100;

  /// E.164 dialling code.
  static const String phoneCountryCode = '+233';

  /// Dialling code without the leading '+', used for normalisation.
  static const String phoneCountryCodeDigits = '233';

  /// IANA timezone identifier.
  static const String timezone = 'Africa/Accra';

  /// BCP-47 locale used for formatting and Material localisation.
  static const String locale = 'en-GH';

  /// Accepted payment methods (spec §9). Provider implementations arrive in
  /// Phase 6; this list drives UI options and backend capability checks.
  static const List<String> supportedPaymentMethods = <String>[
    'mobile_money',
    'bank_transfer',
    'card',
  ];

  /// Local mobile money operators commonly used in Ghana. Kept as data so the
  /// payment feature (Phase 6) can render provider choices generically.
  static const List<String> mobileMoneyOperators = <String>[
    'MTN Mobile Money',
    'Vodafone Cash',
    'AT Money',
    'Telecel Cash',
  ];

  // ---------------------------------------------------------------------------
  // Limits & defaults
  // ---------------------------------------------------------------------------

  /// OTP length used by authentication (spec §10).
  static const int otpLength = 6;

  /// Default page size for paginated lists.
  static const int defaultPageSize = 20;

  /// Maximum members per group (configurable per group in Phase 5).
  static const int defaultMaxGroupMembers = 50;

  /// Default contribution reminder lead time (days) before a due date.
  static const int contributionReminderLeadDays = 1;

  // ---------------------------------------------------------------------------
  // Storage keys (spec §10, §27 — tokens must live in secure storage)
  // ---------------------------------------------------------------------------

  /// Keyspace prefix avoids collisions with other apps.
  static const String storagePrefix = 'digital_susu_v2';

  /// Secure storage keys.
  static const String secureKeyAccessToken = '$storagePrefix.access_token';
  static const String secureKeyRefreshToken = '$storagePrefix.refresh_token';
  static const String secureKeySessionUser = '$storagePrefix.session_user';

  /// Non-sensitive local storage keys.
  static const String localKeyOnboarded = '$storagePrefix.onboarded';
  static const String localKeyNotificationSettings =
      '$storagePrefix.notification_settings';
  static const String localKeyAppPreferences = '$storagePrefix.preferences';
}
