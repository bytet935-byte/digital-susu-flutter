import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../errors/app_exception.dart';
import 'api_config.dart';
import 'api_exception_mapper.dart';
import 'auth_interceptor.dart';
import 'logging_interceptor.dart';
import 'token_refresher.dart';
import 'token_store.dart';

/// Typed HTTP client owning the Dio instance and its interceptors (spec §11).
///
/// All methods throw mapped [AppException]s on failure — callers (repositories)
/// wrap results with `Result<T>` and the UI only ever sees friendly messages.
class ApiClient {
  ApiClient({
    required ApiConfig config,
    required TokenStore tokenStore,
    this.onSessionExpired,
  }) {
    _dio = Dio(config.toBaseOptions());
    _refresher = TokenRefresher(
      dio: _dio,
      tokenStore: tokenStore,
      onSessionExpired: onSessionExpired,
    );
    _authInterceptor = AuthInterceptor(
      tokenStore: tokenStore,
      refresher: _refresher,
    )..attach(_dio);
    _dio.interceptors.addAll(<Interceptor>[
      _authInterceptor,
      LoggingInterceptor(),
    ]);
  }

  /// Invoked when the session can no longer be refreshed (token revoked /
  /// expired) — the app should sign the user out (spec §10, §12).
  final void Function()? onSessionExpired;

  late final Dio _dio;
  late final TokenRefresher _refresher;
  late final AuthInterceptor _authInterceptor;

  /// Raw Dio instance (advanced use; prefer the typed helpers).
  Dio get dio => _dio;

  /// The interceptor, exposed for tests.
  @visibleForTesting
  AuthInterceptor get authInterceptor => _authInterceptor;

  // ---------------------------------------------------------------------------
  // Typed helpers
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMap(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) =>
      _decodeMap(_send(() => _dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
            options: _options(skipAuth),
          )));

  Future<List<dynamic>> getList(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool skipAuth = false,
  }) =>
      _decodeList(_send(() => _dio.get<dynamic>(
            path,
            queryParameters: queryParameters,
            options: _options(skipAuth),
          )));

  Future<Map<String, dynamic>> postMap(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) =>
      _decodeMap(_send(() => _dio.post<dynamic>(
            path,
            data: data,
            options: _options(skipAuth),
          )));

  Future<Map<String, dynamic>> putMap(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) =>
      _decodeMap(_send(() => _dio.put<dynamic>(
            path,
            data: data,
            options: _options(skipAuth),
          )));

  Future<Map<String, dynamic>> patchMap(
    String path, {
    Object? data,
    bool skipAuth = false,
  }) =>
      _decodeMap(_send(() => _dio.patch<dynamic>(
            path,
            data: data,
            options: _options(skipAuth),
          )));

  Future<void> delete(
    String path, {
    bool skipAuth = false,
  }) =>
      _send(() => _dio.delete<dynamic>(
            path,
            options: _options(skipAuth),
          ));

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Options _options(bool skipAuth) =>
      Options(extra: <String, dynamic>{RequestFlags.skipAuth: skipAuth});

  Future<dynamic> _send(Future<Response<dynamic>> Function() run) async {
    try {
      final response = await run();
      return response.data;
    } on DioException catch (error) {
      throw ApiExceptionMapper.fromDioException(error);
    } on AppException {
      rethrow;
    } catch (error) {
      // Last-resort safety net: never surface raw errors to the UI.
      throw NetworkException(cause: error);
    }
  }

  Future<Map<String, dynamic>> _decodeMap(Future<dynamic> dataFuture) async {
    final data = await dataFuture;
    if (data is Map<String, dynamic>) return data;
    throw const MalformedResponseException();
  }

  Future<List<dynamic>> _decodeList(Future<dynamic> dataFuture) async {
    final data = await dataFuture;
    if (data is List<dynamic>) return data;
    throw const MalformedResponseException();
  }
}
