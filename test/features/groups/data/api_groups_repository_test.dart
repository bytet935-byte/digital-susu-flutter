import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/network/api_client.dart';
import 'package:digital_susu/core/network/api_config.dart';
import 'package:digital_susu/core/network/token_store.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/groups/data/api_groups_repository.dart';

import '../../../helpers/fake_dio_adapter.dart';

ResponseBody jsonBody(Object? payload, int status) => ResponseBody.fromString(
      jsonEncode(payload),
      status,
      headers: <String, List<String>>{
        'content-type': <String>['application/json'],
      },
    );

void main() {
  const baseUrl = 'https://api.test/v1';

  late FakeDioAdapter adapter;
  late InMemoryTokenStore tokenStore;
  late ApiGroupsRepository repo;

  ApiGroupsRepository buildRepo() {
    final client = ApiClient(
      config: const ApiConfig(baseUrl: baseUrl, timeout: Duration(seconds: 5)),
      tokenStore: tokenStore,
    );
    client.dio.httpClientAdapter = adapter;
    return ApiGroupsRepository(client);
  }

  setUp(() {
    adapter = FakeDioAdapter();
    tokenStore = InMemoryTokenStore();
    repo = buildRepo();
  });

  const messageRow = <String, dynamic>{
    'id': 'msg_1',
    'group_id': 'grp_weekend',
    'sender_id': 'usr_ama',
    'sender_name': 'Ama Serwaa',
    'body': 'Good evening everyone 🌙',
    'kind': 'MESSAGE',
    'created_at': '2026-08-14T19:00:00.000Z',
  };

  group('ApiGroupsRepository — chat (real backend shapes)', () {
    test('getMessages parses the {messages:[...]} wrapper', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/groups/grp_weekend/messages');
        expect(options.method, 'GET');
        return jsonBody(<String, dynamic>{'messages': <Object?>[messageRow]}, 200);
      };

      final result = await repo.getMessages('grp_weekend');

      expect(result.isSuccess, isTrue);
      final messages = result.valueOrNull!;
      expect(messages, hasLength(1));
      expect(messages.first.senderName, 'Ama Serwaa');
      expect(messages.first.body, 'Good evening everyone 🌙');
    });

    test('sendMessage posts the body and parses the created message',
        () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/groups/grp_weekend/messages');
        expect(options.method, 'POST');
        final body = (options.data as Map<String, dynamic>)['body'];
        expect(body, 'Hello susu!');
        // Echo the created message like the real server does.
        return jsonBody(<String, dynamic>{
          ...messageRow,
          'sender_name': 'Kwame Owusu',
          'body': body,
        }, 201);
      };

      final result = await repo.sendMessage(
        groupId: 'grp_weekend',
        body: 'Hello susu!',
        senderId: 'usr_kwame',
        senderName: 'Kwame Owusu',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.body, 'Hello susu!');
      expect(result.valueOrNull!.senderName, 'Kwame Owusu');
    });
  });
}
