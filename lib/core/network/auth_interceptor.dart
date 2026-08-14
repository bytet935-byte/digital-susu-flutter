import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'api_config.dart';
import 'token_refresher.dart';
import 'token_store.dart';

/// Attaches the access token to protected requests and transparently
/// refreshes + retries once when a request returns 401 (spec §10, §12).
///
/// - Requests marked with [RequestFlags.skipAuth] (public endpoints) never
///   receive a token.
/// - The refresh request itself is marked [RequestFlags.isRefreshRequest] so
///   it can never trigger another refresh (infinite loop guard).
/// - A failed refresh produces [SessionExpiredException], clearing the
///   session (via [TokenRefresher]) — the app reacts through
///   `onSessionExpired`.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({
    required TokenStore tokenStore,
    required TokenRefresher refresher,
  })  : _tokenStore = tokenStore,
        _refresher = refresher;

  final TokenStore _tokenStore;
  final TokenRefresher _refresher;
  Dio? _dio;

  /// Binds the owning Dio instance so the interceptor can replay a request
  /// with a fresh token after refresh.
  void attach(Dio dio) => _dio = dio;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (options.extra[RequestFlags.skipAuth] == true ||
        options.extra[RequestFlags.isRefreshRequest] == true) {
      return handler.next(options);
    }
    final token = await _tokenStore.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    return handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final is401 = err.response?.statusCode == 401;
    final skipAuth = err.requestOptions.extra[RequestFlags.skipAuth] == true;
    final isRefresh =
        err.requestOptions.extra[RequestFlags.isRefreshRequest] == true;
    final alreadyRetried = err.requestOptions.extra[RequestFlags.retried] == true;

    if (!is401 || skipAuth || isRefresh || alreadyRetried) {
      return handler.next(err);
    }

    try {
      final newToken = await _refresher.refreshAccessToken();
      if (newToken == null) {
        // Refresh failed → session expired.
        return handler.reject(DioException(
          requestOptions: err.requestOptions,
          error: const SessionExpiredException(),
          type: DioExceptionType.unknown,
        ));
      }
      err.requestOptions.extra[RequestFlags.retried] = true;
      err.requestOptions.headers['Authorization'] = 'Bearer $newToken';
      final response = await _dio?.fetch(err.requestOptions);
      if (response != null) {
        return handler.resolve(response);
      }
      return handler.next(err);
    } on AppException catch (error) {
      return handler.reject(DioException(
        requestOptions: err.requestOptions,
        error: error,
        type: DioExceptionType.unknown,
      ));
    }
  }
}
