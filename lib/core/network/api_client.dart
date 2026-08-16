import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'api_config.dart';
import 'api_endpoints.dart';
import 'token_store.dart';

/// Typed HTTP client for the Digital Susu backend (spec §12, §27).
///
/// - Sets [ApiConfig.baseUrl] on the underlying Dio instance so repositories
///   pass relative paths only.
/// - Attaches `Authorization: Bearer <access-token>` to every request unless
///   it is marked `skipAuth` (public auth endpoints).
/// - Maps Dio failures onto the typed [AppException] hierarchy so the UI only
///   ever sees friendly, structured errors.
/// - On a 401 for an authenticated request, attempts **one** token refresh via
///   `POST /auth/refresh`; if the refresh fails, fires [onSessionExpired]
///   (wired in `main.dart` to sign the user out) and throws
///   [SessionExpiredException].
class ApiClient {
  ApiClient({
    required ApiConfig config,
    required TokenStore tokenStore,
    this.onSessionExpired,
    Dio? dio,
  })  : _tokenStore = tokenStore,
        dio = dio ??
            Dio(
              BaseOptions(
                baseUrl: config.baseUrl,
                connectTimeout: config.timeout,
                sendTimeout: config.timeout,
                receiveTimeout: config.timeout,
                responseType: ResponseType.json,
                headers: <String, dynamic>{
                  Headers.acceptHeader: Headers.jsonContentType,
                },
              ),
            ) {
    this.dio.interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) async {
              if (options.extra['skipAuth'] == true) {
                handler.next(options);
                return;
              }
              final token = await _tokenStore.readAccessToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
              handler.next(options);
            },
          ),
        );
  }

  final TokenStore _tokenStore;

  /// Fired when the session expires (failed refresh). Wired app-wide in
  /// `main.dart` to sign the user out.
  final void Function()? onSessionExpired;

  /// Exposed for tests (e.g. `client.dio.httpClientAdapter = fake`).
  final Dio dio;

  // ---------------------------------------------------------------------------
  // Typed verbs
  // ---------------------------------------------------------------------------

  Future<Map<String, dynamic>> getMap(
    String path, {
    bool skipAuth = false,
  }) async =>
      _decodeMap(await _request('GET', path, skipAuth: skipAuth));

  Future<List<dynamic>> getList(
    String path, {
    bool skipAuth = false,
  }) async =>
      _decodeList(await _request('GET', path, skipAuth: skipAuth));

  Future<Map<String, dynamic>> postMap(
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async =>
      _decodeMap(await _request('POST', path, data: data, skipAuth: skipAuth));

  Future<Map<String, dynamic>> putMap(
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async =>
      _decodeMap(await _request('PUT', path, data: data, skipAuth: skipAuth));

  Future<Map<String, dynamic>> patchMap(
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async =>
      _decodeMap(await _request('PATCH', path, data: data, skipAuth: skipAuth));

  Future<Map<String, dynamic>> deleteMap(
    String path, {
    bool skipAuth = false,
  }) async =>
      _decodeMap(await _request('DELETE', path, skipAuth: skipAuth));

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<Object?> _request(
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async {
    try {
      return await _send(method, path, data: data, skipAuth: skipAuth);
    } on DioException catch (error) {
      final unauthorized = error.response?.statusCode == 401;
      if (unauthorized && !skipAuth) {
        if (await _tryRefresh()) {
          // Retry the original request once with the fresh token.
          try {
            return await _send(method, path, data: data, skipAuth: skipAuth);
          } on DioException catch (retryError) {
            throw _mapDioError(retryError);
          }
        }
        throw SessionExpiredException(cause: error);
      }
      throw _mapDioError(error);
    }
  }

  Future<Object?> _send(
    String method,
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async {
    final response = await dio.request<Object?>(
      path,
      data: data,
      options: Options(
        method: method,
        extra: <String, dynamic>{'skipAuth': skipAuth},
      ),
    );
    return response.data;
  }

  /// Attempts a single token refresh. Returns `true` when new tokens were
  /// stored. On failure, fires [onSessionExpired] (unless the refresh token
  /// itself is missing).
  Future<bool> _tryRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) return false;
    try {
      final response = await dio.request<Object?>(
        ApiEndpoints.refresh,
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(
          method: 'POST',
          extra: <String, dynamic>{'skipAuth': true},
        ),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) return false;
      final access = data['access_token'];
      final refresh = data['refresh_token'];
      if (access is! String || access.isEmpty) return false;
      if (refresh is! String || refresh.isEmpty) return false;
      await _tokenStore.saveTokens(accessToken: access, refreshToken: refresh);
      return true;
    } on DioException {
      onSessionExpired?.call();
      return false;
    }
  }

  Map<String, dynamic> _decodeMap(Object? data) {
    if (data is Map<String, dynamic>) return data;
    throw const MalformedResponseException();
  }

  List<dynamic> _decodeList(Object? data) {
    if (data is List<dynamic>) return data;
    throw const MalformedResponseException();
  }

  AppException _mapDioError(DioException error) {
    final status = error.response?.statusCode;
    final message = _serverMessage(error.response?.data);
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return ApiTimeoutException(cause: error);
      case DioExceptionType.connectionError:
        return NetworkException(cause: error);
      case DioExceptionType.badCertificate:
        return const NetworkException(
          message: 'The secure connection could not be verified.',
        );
      case DioExceptionType.cancel:
        return const NetworkException(
          message: 'The request was cancelled.',
        );
      case DioExceptionType.badResponse:
        break;
      case DioExceptionType.unknown:
        return NetworkException(cause: error);
    }
    switch (status) {
      case 400:
        return ValidationException(
          message: message ?? 'Please check your details and try again.',
          cause: error,
        );
      case 401:
        return TokenExpiredException(
          message: message ?? 'Your session has expired. Please log in again.',
          cause: error,
        );
      case 403:
        return ForbiddenException(
          message: message ?? 'You do not have permission to do this.',
          cause: error,
        );
      case 404:
        return NotFoundException(
          message: message ?? 'The requested item could not be found.',
          cause: error,
        );
      case 409:
        return ConflictException(
          message: message ?? 'This action conflicts with the current state.',
          cause: error,
        );
      case 429:
        return RateLimitException(
          message: message ?? 'Too many attempts. Please wait a moment.',
          cause: error,
        );
      default:
        if (status != null && status >= 500) {
          return ServerException(
            message: message ?? 'Our servers are having trouble. Please try again shortly.',
            cause: error,
          );
        }
        return MalformedResponseException(cause: error);
    }
  }

  String? _serverMessage(Object? data) {
    if (data is Map<String, dynamic>) {
      final message = data['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    return null;
  }
}
