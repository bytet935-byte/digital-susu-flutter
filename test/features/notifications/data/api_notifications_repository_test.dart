import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/network/api_client.dart';
import 'package:digital_susu/core/network/api_config.dart';
import 'package:digital_susu/core/network/token_store.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/notifications/data/api_notifications_repository.dart';

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
  late ApiNotificationsRepository repo;

  ApiNotificationsRepository buildRepo() {
    final client = ApiClient(
      config: const ApiConfig(baseUrl: baseUrl, timeout: Duration(seconds: 5)),
      tokenStore: tokenStore,
    );
    client.dio.httpClientAdapter = adapter;
    return ApiNotificationsRepository(client);
  }

  setUp(() {
    adapter = FakeDioAdapter();
    tokenStore = InMemoryTokenStore();
    repo = buildRepo();
  });

  const notifRow = <String, dynamic>{
    'id': 'ntf_1',
    'user_id': 'usr_kwame',
    'title': 'New Contribution',
    'body': 'Ama Serwaa contributed GHS 50.00 to Weekend Susu.',
    'category': 'contribution',
    'read': false,
    'created_at': '2026-08-14T09:35:00.000Z',
  };

  group('ApiNotificationsRepository — real backend shapes', () {
    test('getNotifications parses {notifications, unread_count}', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/notifications');
        expect(options.method, 'GET');
        return jsonBody(<String, dynamic>{
          'notifications': <Object?>[notifRow],
          'unread_count': 3,
        }, 200);
      };

      final result = await repo.getNotifications();

      expect(result.isSuccess, isTrue);
      final items = result.valueOrNull!;
      expect(items, hasLength(1));
      expect(items.first.title, 'New Contribution');
      expect(items.first.read, isFalse);
    });

    test('getUnreadCount reads unread_count', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async => jsonBody(
          <String, dynamic>{'notifications': <Object?>[], 'unread_count': 2},
          200);

      final result = await repo.getUnreadCount();

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, 2);
    });

    test('markRead posts to /notifications/:id/read', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/notifications/ntf_1/read');
        expect(options.method, 'POST');
        return jsonBody(<String, dynamic>{'message': 'Marked as read'}, 200);
      };

      final result = await repo.markRead('ntf_1');

      expect(result.isSuccess, isTrue);
    });

    test('markAllRead posts to /notifications/read-all', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/notifications/read-all');
        expect(options.method, 'POST');
        return jsonBody(
            <String, dynamic>{'message': 'All notifications marked as read'},
            200);
      };

      final result = await repo.markAllRead();

      expect(result.isSuccess, isTrue);
    });
  });
}
