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

  group('ApiGroupsRepository — governance (spec §20)', () {
    const proposalRow = <String, dynamic>{
      'id': 'prop_1',
      'group_id': 'grp_weekend',
      'title': 'Move payout day to Saturday',
      'description': 'Shift weekly payouts.',
      'status': 'OPEN',
      'options': <String>['Approve', 'Decline'],
      'votes': <String, int>{'Approve': 6, 'Decline': 4},
      'voting_ends': '2026-08-22T00:00:00.000Z',
      'created_at': '2026-08-15T10:00:00.000Z',
      'created_by_name': 'Kwame Owusu',
    };

    test('getProposals parses the {proposals:[...]} wrapper', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/groups/grp_weekend/proposals');
        expect(options.method, 'GET');
        return jsonBody(
          <String, dynamic>{'proposals': <Object?>[proposalRow]},
          200,
        );
      };

      final result = await repo.getProposals('grp_weekend');

      expect(result.isSuccess, isTrue);
      final proposals = result.valueOrNull!;
      expect(proposals, hasLength(1));
      expect(proposals.first.title, 'Move payout day to Saturday');
      expect(proposals.first.votes['Approve'], 6);
      expect(proposals.first.totalVotes, 10);
    });

    test('vote posts the option and re-fetches the updated proposal',
        () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        if (options.method == 'POST') {
          expect(options.path, '/groups/grp_weekend/proposals/prop_1/vote');
          expect((options.data as Map<String, dynamic>)['option'], 'Approve');
          return jsonBody(<String, dynamic>{'message': 'Vote recorded'}, 201);
        }
        expect(options.path, '/groups/grp_weekend/proposals');
        return jsonBody(<String, dynamic>{
          'proposals': <Object?>[
            <String, dynamic>{...proposalRow, 'votes': <String, int>{'Approve': 7, 'Decline': 4}},
          ],
        }, 200);
      };

      final result = await repo.voteProposal(
        groupId: 'grp_weekend',
        proposalId: 'prop_1',
        option: 'Approve',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.votes['Approve'], 7);
    });
  });

  group('ApiGroupsRepository — member management (build spec §16)', () {
    const memberRow = <String, dynamic>{
      'user_id': 'usr_adjoa',
      'full_name': 'Adjoa Asante',
      'phone': '0209998887',
      'role': 'MEMBER',
    };

    test('addMember posts the identifier to /groups/:id/members', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/groups/grp_weekend/members');
        expect(options.method, 'POST');
        expect(
          (options.data as Map<String, dynamic>)['identifier'],
          '0209998887',
        );
        return jsonBody(memberRow, 201);
      };

      final result = await repo.addMember(
        groupId: 'grp_weekend',
        identifier: '0209998887',
        actorId: 'usr_kwame',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.fullName, 'Adjoa Asante');
      expect(result.valueOrNull!.role, 'MEMBER');
    });

    test('updateMemberRole PATCHes the role to the member path', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/groups/grp_weekend/members/usr_kofi');
        expect(options.method, 'PATCH');
        expect((options.data as Map<String, dynamic>)['role'], 'TREASURER');
        return jsonBody(
          <String, dynamic>{
            ...memberRow,
            'user_id': 'usr_kofi',
            'role': 'TREASURER',
          },
          200,
        );
      };

      final result = await repo.updateMemberRole(
        groupId: 'grp_weekend',
        memberId: 'usr_kofi',
        role: 'TREASURER',
        actorId: 'usr_kwame',
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.userId, 'usr_kofi');
      expect(result.valueOrNull!.role, 'TREASURER');
    });

    test('removeMember DELETEs the member path', () async {
      await tokenStore.saveTokens(accessToken: 'at-1', refreshToken: 'rt-1');
      adapter.handler = (options) async {
        expect(options.path, '/groups/grp_weekend/members/usr_kofi');
        expect(options.method, 'DELETE');
        return jsonBody(<String, dynamic>{'message': 'Member removed'}, 200);
      };

      final result = await repo.removeMember(
        groupId: 'grp_weekend',
        memberId: 'usr_kofi',
        actorId: 'usr_kwame',
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
