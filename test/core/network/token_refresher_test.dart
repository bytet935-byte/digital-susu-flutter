import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/network/api_config.dart';
import 'package:digital_susu/core/network/token_refresher.dart';
import 'package:digital_susu/core/network/token_store.dart';

import '../../helpers/fake_dio_adapter.dart';

void main() {
  const baseUrl = 'https://api.test/v1';

  late Dio dio;
  late FakeDioAdapter adapter;
  late InMemoryTokenStore store;
  var sessionExpired = false;

  TokenRefresher buildRefresher() => TokenRefresher(
        dio: dio,
        tokenStore: store,
        onSessionExpired: () => sessionExpired = true,
      );

  setUp(() {
    dio = Dio(BaseOptions(baseUrl: baseUrl));
    adapter = FakeDioAdapter();
    dio.httpClientAdapter = adapter;
    store = InMemoryTokenStore();
    sessionExpired = false;
  });

  group('TokenRefresher', () {
    test('refreshes tokens and persists the new pair', () async {
      await store.saveTokens(
          accessToken: 'old-access', refreshToken: 'old-refresh');
      adapter.handler = (options) async =>
          jsonBody(<String, dynamic>{'access_token': 'new-access', 'refresh_token': 'new-refresh'}, 200);

      final token = await buildRefresher().refreshAccessToken();

      expect(token, 'new-access');
      expect(await store.readAccessToken(), 'new-access');
      expect(await store.readRefreshToken(), 'new-refresh');
      expect(sessionExpired, isFalse);
    });

    test('rejected refresh token clears the session (spec §10)', () async {
      await store.saveTokens(
          accessToken: 'old-access', refreshToken: 'expired-refresh');
      adapter.handler = (options) async =>
          jsonBody(<String, dynamic>{'message': 'invalid refresh token'}, 401);

      final token = await buildRefresher().refreshAccessToken();

      expect(token, isNull);
      expect(await store.readAccessToken(), isNull);
      expect(await store.readRefreshToken(), isNull);
      expect(sessionExpired, isTrue);
    });

    test('missing refresh token ends the session without a network call',
        () async {
      adapter.handler = (options) async => jsonBody(<String, dynamic>{}, 200);

      final token = await buildRefresher().refreshAccessToken();

      expect(token, isNull);
      expect(adapter.requestCount, 0);
      expect(sessionExpired, isTrue);
    });

    test('refresh request is marked so it never re-triggers refresh',
        () async {
      await store.saveTokens(
          accessToken: 'a', refreshToken: 'r');
      adapter.handler = (options) async {
        expect(options.extra[RequestFlags.skipAuth], isTrue);
        expect(options.extra[RequestFlags.isRefreshRequest], isTrue);
        return jsonBody(<String, dynamic>{'access_token': 'new'}, 200);
      };

      await buildRefresher().refreshAccessToken();
    });

    test('concurrent callers share a single refresh (no refresh storm)',
        () async {
      await store.saveTokens(
          accessToken: 'a', refreshToken: 'r');
      adapter.handler = (options) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return jsonBody(<String, dynamic>{'access_token': 'shared'}, 200);
      };

      final refresher = buildRefresher();
      final results = await Future.wait<String?>(<Future<String?>>[
        refresher.refreshAccessToken(),
        refresher.refreshAccessToken(),
      ]);

      expect(results, <String?>['shared', 'shared']);
      expect(adapter.requestCount, 1, reason: 'single-flight expected');
    });
  });
}
