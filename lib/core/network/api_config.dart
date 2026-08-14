import 'package:dio/dio.dart';

import '../config/environment.dart';

/// Dio configuration for the Digital Susu API (spec §11).
class ApiConfig {
  const ApiConfig({required this.baseUrl, required this.timeout});

  /// Builds config from compile-time environment flags.
  factory ApiConfig.fromEnvironment() => ApiConfig(
        baseUrl: AppEnvironment.apiBaseUrl,
        timeout: AppEnvironment.apiTimeout,
      );

  final String baseUrl;
  final Duration timeout;

  BaseOptions toBaseOptions() => BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: timeout,
        receiveTimeout: timeout,
        sendTimeout: timeout,
        headers: <String, dynamic>{
          Headers.acceptHeader: Headers.jsonContentType,
        },
        contentType: Headers.jsonContentType,
      );
}

/// Well-known request option flags used by interceptors.
abstract final class RequestFlags {
  /// When set, [AuthInterceptor] does not attach an access token.
  static const String skipAuth = 'skipAuth';

  /// Marks the token-refresh request so it never triggers another refresh.
  static const String isRefreshRequest = 'isRefreshRequest';

  /// Marks a request that already retried after a token refresh.
  static const String retried = 'retried';
}
