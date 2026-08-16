import '../config/environment.dart';

/// Compile-time API configuration (spec §12).
///
/// Values come from `--dart-define` flags via [AppEnvironment]; tests build
/// explicit const instances.
class ApiConfig {
  const ApiConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
  });

  /// Builds the config from `--dart-define` values (USE_MOCK_DATA is handled
  /// by the repository selector; this carries the base URL and timeout).
  factory ApiConfig.fromEnvironment() => const ApiConfig(
        baseUrl: AppEnvironment.apiBaseUrl,
        timeout: AppEnvironment.apiTimeout,
      );

  /// Base URL of the backend, e.g. `https://api.example.com/v1`.
  final String baseUrl;

  /// Request/response timeout (spec §12).
  final Duration timeout;
}
