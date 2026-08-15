import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/groups/data/mock_groups_repository.dart';
import 'package:digital_susu/features/groups/domain/group_models.dart';

void main() {
  late MockGroupsRepository repo;

  setUp(() {
    repo = MockGroupsRepository();
  });

  group('MockGroupsRepository — groups (spec §6, §14)', () {
    test('returns design-reference groups with statuses', () async {
      final groups = (await repo.getMyGroups()).valueOrNull!;
      expect(groups, hasLength(4));
      final active = groups.where((g) => g.isActive).toList();
      expect(active.map((g) => g.name),
          containsAll(<String>['Weekend Susu', 'Project Susu', 'Business Susu']));
      expect(groups.any((g) => g.status == GroupStatuses.completed), isTrue);
    });

    test('group details resolve by id and reject unknown ids', () async {
      final group = (await repo.getGroup('grp_weekend')).valueOrNull!;
      expect(group.name, 'Weekend Susu');
      expect(group.pot.amountMinor, 50000);
      expect(group.memberCount, 10);

      final missing = await repo.getGroup('grp_unknown');
      expect(missing, isA<Failure<SusuGroup>>());
      expect((missing as Failure<SusuGroup>).error, isA<NotFoundException>());
    });

    test('createGroup validates the name and makes the creator owner', () async {
      final invalid = await repo.createGroup(name: 'A', type: GroupTypes.rotationalSusu);
      expect(invalid, isA<Failure<SusuGroup>>());
      expect((invalid as Failure<SusuGroup>).error, isA<ValidationException>());

      final created = (await repo.createGroup(
        name: 'New Susu',
        type: GroupTypes.savingsGoal,
      )).valueOrNull!;
      expect(created.status, GroupStatuses.active);
      expect(created.memberCount, 1);
      final members = (await repo.getMembers(created.id)).valueOrNull!;
      expect(members.first.role, GroupRoles.owner);
    });

    test('joinGroup adds the user (FLOW 3)', () async {
      final group = (await repo.joinGroup('WEEKEND-2026')).valueOrNull!;
      expect(group.id, 'grp_weekend');
      final members = (await repo.getMembers(group.id)).valueOrNull!;
      expect(members.any((m) => m.userId == MockGroupsRepository.currentUserId),
          isTrue);
    });
  });

  group('MockGroupsRepository — chat (build spec §10)', () {
    test('messages arrive newest first', () async {
      final messages = (await repo.getMessages('grp_weekend')).valueOrNull!;
      expect(messages, isNotEmpty);
      expect(messages.first.senderName, 'Ama Serwaa');
    });

    test('sendMessage appends and validates', () async {
      final sent = (await repo.sendMessage(
        groupId: 'grp_weekend',
        body: 'Hello team',
        senderId: MockGroupsRepository.currentUserId,
        senderName: 'Kwame Owusu',
      )).valueOrNull!;
      expect(sent.body, 'Hello team');

      final empty = await repo.sendMessage(
        groupId: 'grp_weekend',
        body: '   ',
        senderId: 'x',
        senderName: 'x',
      );
      expect(empty, isA<Failure<GroupMessage>>());
    });
  });
}
