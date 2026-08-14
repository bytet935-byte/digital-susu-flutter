import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/network/api_client.dart';
import 'package:digital_susu/core/network/api_config.dart';
import 'package:digital_susu/core/network/token_store.dart';

import '../../helpers/fake_dio_adapter.dart';

void main() {
  const baseUrl = 'https://api.test/v1';

  late FakeDioAdapter adapter;
  late InMemoryTokenStore store;

  setUp(() {
    adapter = FakeDioAdapter();
    store = InMemoryTokenStore();
  });

  ApiClient buildClient() {
    final client = ApiClient(
      config: const ApiConfig(
        baseUrl: baseUrl,
        timeout: Duration(seconds: 5),
      ),
      tokenStore: store,
    );
    client.dio.httpClientAdapter = adapter;
    return client;
  }

  group('AuthInterceptor', () {
    test('attaches the access token to protected requests', () async {
      await store.saveTokens(
          accessToken: 'access-1', refreshToken: 'refresh-1');
      adapter.handler = (options) async =>
          jsonBody(<String, dynamic>{'ok': true}, 200);

      await buildClient().getMap('/wallet');

      expect(adapter.lastOptions?.headers['Authorization'], 'Bearer access-1');
    });

    test('skips token attach for public (skipAuth) requests', () async {
      await store.saveTokens(
          accessToken: 'access-1', refreshToken: 'refresh-1');
      adapter.handler = (options) async =>
          jsonBody(<String, dynamic>{'ok': true}, 200);

      await buildClient().getMap('/auth/login', skipAuth: true);

      expect(adapter.lastOptions?.headers.containsKey('Authorization'), isFalse);
    });

    test('401 triggers refresh and retries once with the new token', () async {
      await store.saveTokens(
          accessToken: 'expired', refreshToken: 'valid-refresh');
      adapter.handler = (options) async {
        if (options.path == '/auth/refresh') {
          return jsonBody(<String, dynamic>{
            'access_token': 'fresh-access',
            'refresh_token': 'new-refresh',
          }, 200);
        }
        if (options.headers['Authorization'] == 'Bearer fresh-access') {
          return jsonBody(<String, dynamic>{'ok': true}, 200);
        }
        return jsonBody(<String, dynamic>{'message': 'expired'}, 401);
      };

      final data = await buildClient().getMap('/protected');

      expect(data['ok'], isTrue);
      expect(await store.readAccessToken(), 'fresh-access');
      expect(await store.readRefreshToken(), 'new-refresh');
    });

    test('failed refresh rejects with SessionExpiredException', () async {
      await store.saveTokens(
          accessToken: 'expired', refreshToken: 'bad-refresh');
      adapter.handler = (options) async {
        if (options.path == '/auth/refresh') {
          return jsonBody(<String, dynamic>{'message': 'rejected'}, 401);
        }
        return jsonBody(<String, dynamic>{'message': 'expired'}, 401);
      };

      await expectLater(
        buildClient().getMap('/protected'),
        throwsA(isA<SessionExpiredException>()),
      );
      expect(await store.readAccessToken(), isNull,
          reason: 'session cleared after failed refresh');
    });

    test('retries only once (no refresh loop)', () async {
      await store.saveTokens(
          accessToken: 'expired', refreshToken: 'valid-refresh');
      adapter.handler = (options) async {
        if (options.path == '/auth/refresh') {
          return jsonBody(<String, dynamic>{'access_token': 'fresh'}, 200);
        }
        // Even the retried request fails with 401 — must NOT refresh again.
        return jsonBody(<String, dynamic>{'message': 'forbidden'}, 401);
      };

      await expectLater(
        buildClient().getMap('/protected'),
        throwsA(isA<TokenExpiredException>()),
      );
      expect(adapter.requestCount, 3,
          reason: 'original + refresh + single retry — no refresh loop');
    });
  });
}
