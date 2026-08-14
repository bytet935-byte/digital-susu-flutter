import 'package:dio/dio.dart';

import '../errors/app_exception.dart';
import 'api_config.dart';
import 'api_endpoints.dart';
import 'api_exception_mapper.dart';
import 'token_store.dart';

/// Refreshes the access token using the stored refresh token (spec §10).
///
/// **Single-flight guarantee:** concurrent callers (e.g. several requests
/// hitting 401 at once) share one refresh request, preventing refresh storms
/// and race conditions (spec §28).
///
/// On an invalid/expired refresh token the session is cleared and
/// [onSessionExpired] is invoked so the app can sign out the user.
class TokenRefresher {
  TokenRefresher({
    required Dio dio,
    required TokenStore tokenStore,
    this.onSessionExpired,
    this.refreshEndpoint = ApiEndpoints.refreshToken,
  })  : _dio = dio,
        _tokenStore = tokenStore;

  final Dio _dio;
  final TokenStore _tokenStore;
  final void Function()? onSessionExpired;
  final String refreshEndpoint;

  Future<String?>? _inFlight;

  /// Returns the new access token, or `null` when the session could not be
  /// refreshed (session expired). Non-auth failures (network, server) are
  /// rethrown as mapped [AppException]s.
  Future<String?> refreshAccessToken() {
    final inFlight = _inFlight;
    if (inFlight != null) return inFlight;
    final future = _doRefresh();
    _inFlight = future;
    // Clear the in-flight reference after completion so the next 401 retries.
    return future.whenComplete(() => _inFlight = null);
  }

  Future<String?> _doRefresh() async {
    final refreshToken = await _tokenStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _expireSession();
      return null;
    }

    try {
      final response = await _dio.post<dynamic>(
        refreshEndpoint,
        data: <String, dynamic>{'refresh_token': refreshToken},
        options: Options(extra: <String, dynamic>{
          RequestFlags.skipAuth: true,
          RequestFlags.isRefreshRequest: true,
        }),
      );
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        throw const MalformedResponseException();
      }
      final accessToken = data['access_token'];
      if (accessToken is! String || accessToken.isEmpty) {
        throw const MalformedResponseException();
      }
      final newRefreshToken =
          data['refresh_token'] is String ? data['refresh_token'] as String : refreshToken;
      await _tokenStore.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      return accessToken;
    } on DioException catch (error) {
      final mapped = ApiExceptionMapper.fromDioException(error);
      if (mapped is TokenExpiredException || mapped is UnauthorizedException) {
        // The refresh token itself is rejected — the session is over.
        await _expireSession();
        return null;
      }
      rethrow;
    }
  }

  Future<void> _expireSession() async {
    await _tokenStore.clear();
    onSessionExpired?.call();
  }
}
