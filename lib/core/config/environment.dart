/// Compile-time environment configuration.
///
/// Values are injected with `--dart-define`, e.g.:
///
/// ```sh
/// flutter run --dart-define=USE_MOCK_DATA=true
/// flutter run --dart-define=USE_MOCK_DATA=false \
///   --dart-define=API_BASE_URL=https://api.example.com/v1
/// ```
///
/// `bool.fromEnvironment` accepts `true`/`false` strings when passed through
/// `--dart-define`, matching the spec's `USE_MOCK_DATA=true` example (§11).
abstract final class AppEnvironment {
  /// When `true`, repositories serve mock data and no network calls are made
  /// (spec §11). Defaults to `true` so the app runs out of the box in dev.
  static const bool useMockData = bool.fromEnvironment(
    'USE_MOCK_DATA',
    defaultValue: true,
  );

  /// Base URL of the real backend API (used when [useMockData] is `false`).
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.digitalsusu.example.com/v1',
  );

  /// Enables verbose logging (network, navigation) in debug builds.
  static const bool debugLogging = bool.fromEnvironment(
    'DEBUG_LOGGING',
    defaultValue: false,
  );

  /// Request/response timeout for API calls (spec §12).
  static const Duration apiTimeout = Duration(seconds: 30);
}
