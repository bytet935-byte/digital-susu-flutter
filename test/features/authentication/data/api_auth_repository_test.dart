import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/config/app_config.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/core/network/api_client.dart';
import 'package:digital_susu/core/network/api_config.dart';
import 'package:digital_susu/core/network/token_store.dart';
import 'package:digital_susu/core/storage/storage_service.dart';
import 'package:digital_susu/features/authentication/data/repositories/api_auth_repository.dart';
import 'package:digital_susu/features/authentication/domain/models/auth_session.dart';

import '../../../helpers/fake_dio_adapter.dart';

class FakeSecureStorage implements SecureStorageService {
  final Map<String, String> store = <String, String>{};

  @override
  Future<String?> read(String key) async => store[key];

  @override
  Future<void> write(String key, String value) async => store[key] = value;

  @override
  Future<void> delete(String key) async => store.remove(key);

  @override
  Future<void> clear() async => store.clear();
}

void main() {
  const baseUrl = 'https://api.test/v1';

  late FakeDioAdapter adapter;
  late InMemoryTokenStore tokenStore;
  late FakeSecureStorage secure;
  late ApiAuthRepository repo;

  ApiAuthRepository buildRepo() {
    final client = ApiClient(
      config: const ApiConfig(
        baseUrl: baseUrl,
        timeout: Duration(seconds: 5),
      ),
      tokenStore: tokenStore,
    );
    client.dio.httpClientAdapter = adapter;
    return ApiAuthRepository(
      client: client,
      tokenStore: tokenStore,
      secureStorage: secure,
    );
  }

  Map<String, dynamic> sessionPayload() => <String, dynamic>{
        'access_token': 'at-1',
        'refresh_token': 'rt-1',
        'user': <String, dynamic>{
          'id': 'usr_1',
          'full_name': 'Kwame Owusu',
          'phone': '+233241234567',
          'email': 'kwame@digitalsusu.example',
          'kyc_status': 'PENDING',
          'created_at': '2026-01-15T00:00:00.000',
        },
      };

  setUp(() {
    adapter = FakeDioAdapter();
    tokenStore = InMemoryTokenStore();
    secure = FakeSecureStorage();
    repo = buildRepo();
  });

  group('ApiAuthRepository — login/register/verify (spec §10)', () {
    test('login persists tokens and returns a session', () async {
      adapter.handler = (options) async {
        expect(options.path, '/auth/login');
        expect((options.data as Map<String, dynamic>)['identifier'],
            '0241234567');
        return jsonBody(sessionPayload(), 200);
      };

      final result = await repo.login(
        identifier: '0241234567',
        password: '123456',
      );

      expect(result.isSuccess, isTrue);
      expect(await tokenStore.readAccessToken(), 'at-1');
      expect(await tokenStore.readRefreshToken(), 'rt-1');
      expect(secure.store[AppConfig.secureKeySessionUser], isNotNull);
    });

    test('login failure maps to a typed AppException', () async {
      adapter.handler = (options) async =>
          jsonBody(<String, dynamic>{'message': 'invalid credentials'}, 401);

      final result = await repo.login(
        identifier: '0241234567',
        password: 'bad',
      );
      expect(result, isA<Failure<AuthSession>>());
      expect((result as Failure<AuthSession>).error, isA<TokenExpiredException>());
    });

    test('register posts the profile', () async {
      adapter.handler = (options) async {
        expect(options.path, '/auth/register');
        final body = options.data as Map<String, dynamic>;
        expect(body['full_name'], 'Ama Serwaa');
        return jsonBody(<String, dynamic>{
          'id': 'usr_2',
          'full_name': 'Ama Serwaa',
          'phone': '+233551234567',
          'kyc_status': 'NOT_STARTED',
          'created_at': '2026-08-15T00:00:00.000',
        }, 201);
      };

      final result = await repo.register(
        fullName: 'Ama Serwaa',
        identifier: '0551234567',
        password: 'secret1',
      );
      expect(result.isSuccess, isTrue);
    });

    test('verifyOtp persists tokens', () async {
      adapter.handler = (options) async {
        expect(options.path, '/auth/verify-otp');
        final body = options.data as Map<String, dynamic>;
        expect(body['code'], '123456');
        return jsonBody(sessionPayload(), 200);
      };

      final result =
          await repo.verifyOtp(phone: '0241234567', code: '123456');
      expect(result.isSuccess, isTrue);
      expect(await tokenStore.readAccessToken(), 'at-1');
    });
  });

  group('ApiAuthRepository — restoreSession', () {
    test('returns null when no tokens exist', () async {
      final result = await repo.restoreSession();
      expect(result.valueOrNull, isNull);
    });

    test('validates the access token via /users/me', () async {
      await tokenStore.saveTokens(
          accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/users/me');
        expect(options.headers['Authorization'], 'Bearer at-1');
        return jsonBody(<String, dynamic>{
          'id': 'usr_1',
          'full_name': 'Kwame Owusu',
          'phone': '+233241234567',
          'kyc_status': 'PENDING',
          'created_at': '2026-01-15T00:00:00.000',
        }, 200);
      };

      final result = await repo.restoreSession();
      final session = result.valueOrNull;
      expect(session, isNotNull);
      expect(session!.user.fullName, 'Kwame Owusu');
    });

    test('rejected token clears the session (session expiry)', () async {
      await tokenStore.saveTokens(
          accessToken: 'expired', refreshToken: 'bad-refresh');
      adapter.handler = (options) async {
        // Both the /users/me call and the refresh attempt fail with 401.
        return jsonBody(<String, dynamic>{'message': 'expired'}, 401);
      };

      final result = await repo.restoreSession();
      expect(result.valueOrNull, isNull);
      expect(await tokenStore.readAccessToken(), isNull);
      expect(await tokenStore.readRefreshToken(), isNull);
    });

    test('network failure falls back to the cached profile', () async {
      await tokenStore.saveTokens(
          accessToken: 'at-1', refreshToken: 'rt-1');
      secure.store[AppConfig.secureKeySessionUser] =
          '{"id":"usr_1","full_name":"Kwame Owusu","phone":"+233241234567",'
          '"kyc_status":"PENDING","created_at":"2026-01-15T00:00:00.000"}';
      adapter.handler = (options) async => throw dioError(options);

      final result = await repo.restoreSession();
      final session = result.valueOrNull;
      expect(session, isNotNull,
          reason: 'offline restore must not log the user out');
      expect(await tokenStore.readAccessToken(), 'at-1',
          reason: 'tokens survive an offline restore');
    });
  });

  group('ApiAuthRepository — logout', () {
    test('clears local tokens and cache', () async {
      await tokenStore.saveTokens(
          accessToken: 'at-1', refreshToken: 'rt-1');
      secure.store[AppConfig.secureKeySessionUser] = '{}';
      adapter.handler = (options) async {
        expect(options.path, '/auth/logout');
        return jsonBody(<String, dynamic>{'ok': true}, 200);
      };

      final result = await repo.logout();
      expect(result.isSuccess, isTrue);
      expect(await tokenStore.readAccessToken(), isNull);
      expect(secure.store.containsKey(AppConfig.secureKeySessionUser), isFalse);
    });
  });
}
