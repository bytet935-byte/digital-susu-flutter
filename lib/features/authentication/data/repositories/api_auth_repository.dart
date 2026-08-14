import 'dart:convert';

import '../../../../core/config/app_config.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/network/token_store.dart';
import '../../../../core/storage/storage_service.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Real-backend auth repository (USE_MOCK_DATA=false).
///
/// Tokens are persisted through [TokenStore] (secure storage) — spec §10, §27.
/// Session restore validates the access token via `/users/me` and tolerates
/// offline startup by falling back to the cached profile.
class ApiAuthRepository implements AuthRepository {
  ApiAuthRepository({
    required ApiClient client,
    required TokenStore tokenStore,
    required SecureStorageService secureStorage,
  })  : _client = client,
        _tokenStore = tokenStore,
        _secure = secureStorage;

  final ApiClient _client;
  final TokenStore _tokenStore;
  final SecureStorageService _secure;

  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
  }) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.login,
        data: <String, dynamic>{
          'identifier': identifier,
          'password': password,
        },
        skipAuth: true,
      );
      return Success<AuthSession>(await _persistSession(data));
    } on AppException catch (error) {
      return Failure<AuthSession>(error);
    }
  }

  @override
  Future<Result<User>> register({
    required String fullName,
    required String identifier,
    required String password,
  }) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.register,
        data: <String, dynamic>{
          'full_name': fullName,
          'identifier': identifier,
          'password': password,
        },
        skipAuth: true,
      );
      return Success<User>(User.fromJson(data));
    } on AppException catch (error) {
      return Failure<User>(error);
    }
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.verifyOtp,
        data: <String, dynamic>{'phone': phone, 'code': code},
        skipAuth: true,
      );
      return Success<AuthSession>(await _persistSession(data));
    } on AppException catch (error) {
      return Failure<AuthSession>(error);
    }
  }

  @override
  Future<Result<void>> resendOtp({required String phone}) async {
    try {
      await _client.postMap(
        ApiEndpoints.resendOtp,
        data: <String, dynamic>{'phone': phone},
        skipAuth: true,
      );
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    }
  }

  @override
  Future<Result<void>> forgotPassword({required String identifier}) async {
    try {
      await _client.postMap(
        ApiEndpoints.forgotPassword,
        data: <String, dynamic>{'identifier': identifier},
        skipAuth: true,
      );
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    }
  }

  @override
  Future<Result<void>> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    try {
      await _client.postMap(
        ApiEndpoints.resetPassword,
        data: <String, dynamic>{'code': code, 'new_password': newPassword},
        skipAuth: true,
      );
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    }
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    final access = await _tokenStore.readAccessToken();
    final refresh = await _tokenStore.readRefreshToken();
    if (access == null || access.isEmpty) {
      return const Success<AuthSession?>(null);
    }
    try {
      final data = await _client.getMap(ApiEndpoints.me);
      final user = User.fromJson(data);
      await _cacheUser(user);
      return Success<AuthSession?>(
        AuthSession(accessToken: access, refreshToken: refresh ?? '', user: user),
      );
    } on TokenExpiredException {
      await _clearSession();
      return const Success<AuthSession?>(null);
    } on SessionExpiredException {
      await _clearSession();
      return const Success<AuthSession?>(null);
    } on AppException {
      // Offline/server trouble at startup: fall back to the cached profile
      // without destroying the tokens — they survive for the next attempt.
      final cached = await _cachedUser();
      if (cached != null) {
        return Success<AuthSession?>(
          AuthSession(
            accessToken: access,
            refreshToken: refresh ?? '',
            user: cached,
          ),
        );
      }
      return const Success<AuthSession?>(null);
    }
  }

  @override
  Future<Result<void>> logout() async {
    try {
      await _client.postMap(ApiEndpoints.logout);
    } on AppException {
      // Best-effort server sign-out; local session is cleared regardless.
    }
    await _clearSession();
    return const Success<void>(null);
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  Future<AuthSession> _persistSession(Map<String, dynamic> data) async {
    final access = data['access_token'];
    final refresh = data['refresh_token'];
    final userJson = data['user'];
    if (access is! String || access.isEmpty ||
        refresh is! String || refresh.isEmpty ||
        userJson is! Map<String, dynamic>) {
      throw const MalformedResponseException();
    }
    final user = User.fromJson(userJson);
    await _tokenStore.saveTokens(accessToken: access, refreshToken: refresh);
    await _cacheUser(user);
    return AuthSession(accessToken: access, refreshToken: refresh, user: user);
  }

  Future<void> _cacheUser(User user) => _secure.write(
        AppConfig.secureKeySessionUser,
        jsonEncode(user.toJson()),
      );

  Future<User?> _cachedUser() async {
    final raw = await _secure.read(AppConfig.secureKeySessionUser);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map<String, dynamic> ? User.fromJson(decoded) : null;
    } catch (_) {
      return null;
    }
  }

  Future<void> _clearSession() async {
    await _tokenStore.clear();
    await _secure.delete(AppConfig.secureKeySessionUser);
  }
}
