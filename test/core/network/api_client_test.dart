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

  setUp(() {
    adapter = FakeDioAdapter();
    store = InMemoryTokenStore();
  });

  group('ApiClient', () {
    test('getMap decodes JSON responses', () async {
      adapter.handler = (options) async =>
          jsonBody(<String, dynamic>{'balance': 1250}, 200);

      final data = await buildClient().getMap('/wallet');

      expect(data['balance'], 1250);
    });

    test('getList decodes JSON arrays', () async {
      adapter.handler = (options) async =>
          jsonBody(<Map<String, dynamic>>[<String, dynamic>{'id': 't1'}], 200);

      final data = await buildClient().getList('/transactions');

      expect(data, hasLength(1));
    });

    test('server 500 maps to ServerException with friendly message', () async {
      adapter.handler = (options) async => jsonBody(
          <String, dynamic>{'message': 'database unavailable'}, 500);

      await expectLater(
        buildClient().getMap('/groups'),
        throwsA(isA<ServerException>()
            .having((e) => e.message, 'message', 'database unavailable')),
      );
    });

    test('connection failure maps to NetworkException', () async {
      adapter.handler = (options) async => throw dioError(options);

      await expectLater(
        buildClient().getMap('/groups'),
        throwsA(isA<NetworkException>()),
      );
    });

    test('non-object response maps to MalformedResponseException', () async {
      // Valid JSON but the wrong shape for getMap — the client must not
      // return garbage to callers.
      adapter.handler = (options) async => jsonBody(<int>[1, 2, 3], 200);

      await expectLater(
        buildClient().getMap('/groups'),
        throwsA(isA<MalformedResponseException>()),
      );
    });

    test('postMap sends the request body', () async {
      adapter.handler = (options) async {
        expect(options.path, '/payments');
        expect(options.data, <String, dynamic>{'amount': 50});
        return jsonBody(<String, dynamic>{'id': 'p1'}, 201);
      };

      final data =
          await buildClient().postMap('/payments', data: <String, dynamic>{'amount': 50});

      expect(data['id'], 'p1');
    });
  });
}
