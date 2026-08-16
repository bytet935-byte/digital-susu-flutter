import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/groups/data/mock_groups_repository.dart';
import 'package:digital_susu/features/groups/domain/group_models.dart';
import 'package:digital_susu/shared/models/money.dart';

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

  group('MockGroupsRepository — contributions (spec §9)', () {
    test('contribute adds to the pot and returns a receipt', () async {
      final before = (await repo.getGroup('grp_weekend')).valueOrNull!;
      expect(before.pot, const Money(50000));
      expect(before.myContribution, const Money(15000));
      expect(before.myTarget, const Money(50000));

      final result = await repo.contribute(
        groupId: 'grp_weekend',
        amount: const Money(5000),
        paymentMethod: 'MOBILE_MONEY',
        idempotencyKey: 'contrib_test_1',
      );

      expect(result.isSuccess, isTrue);
      final receipt = result.valueOrNull!;
      expect(receipt.amount, const Money(5000));
      expect(receipt.paymentMethod, 'MOBILE_MONEY');
      expect(receipt.groupId, 'grp_weekend');

      final after = (await repo.getGroup('grp_weekend')).valueOrNull!;
      expect(after.pot, const Money(55000));
      expect(after.myContribution, const Money(20000));
    });

    test('contribute rejects invalid amounts and unknown groups', () async {
      final zero = await repo.contribute(
        groupId: 'grp_weekend',
        amount: const Money(0),
        paymentMethod: 'CARD',
        idempotencyKey: 'contrib_test_2',
      );
      expect(zero, isA<Failure<GroupContribution>>());
      expect((zero as Failure<GroupContribution>).error,
          isA<ValidationException>());

      final missing = await repo.contribute(
        groupId: 'grp_unknown',
        amount: const Money(1000),
        paymentMethod: 'CARD',
        idempotencyKey: 'contrib_test_3',
      );
      expect(missing, isA<Failure<GroupContribution>>());
      expect((missing as Failure<GroupContribution>).error,
          isA<NotFoundException>());
    });
  });

  group('MockGroupsRepository — invite codes', () {
    test('returns a deterministic code per group', () async {
      final weekend = (await repo.getInviteCode('grp_weekend')).valueOrNull!;
      expect(weekend, 'SUSU-4821');
      expect((await repo.getInviteCode('grp_project')).valueOrNull,
          'SUSU-7395');
    });

    test('rejects unknown groups', () async {
      final result = await repo.getInviteCode('grp_unknown');
      expect(result, isA<Failure<String>>());
      expect((result as Failure<String>).error, isA<NotFoundException>());
    });
  });

  group('MockGroupsRepository — payout schedule (Phase 7)', () {
    test('returns the rotational cycle with upcoming turns', () async {
      final result = await repo.getPayoutSchedule('grp_weekend');

      expect(result.isSuccess, isTrue);
      final schedule = result.valueOrNull!;
      expect(schedule.cycleNumber, 12);
      expect(schedule.totalCycles, 26);
      expect(schedule.frequencyLabel, 'Weekly');
      expect(schedule.contributionPerCycle, const Money(10000));
      expect(schedule.payoutAmount, const Money(100000));
      expect(schedule.upcomingPayouts, hasLength(4));
      expect(schedule.upcomingPayouts.first.memberName, 'Ama Serwaa');
      expect(schedule.upcomingPayouts.first.date, DateTime(2026, 8, 25));
      expect(schedule.progress, closeTo(12 / 26, 0.0001));
    });

    test('fails for non-rotational group types', () async {
      final result = await repo.getPayoutSchedule('grp_project');
      expect(result, isA<Failure<SusuSchedule>>());
      expect((result as Failure<SusuSchedule>).error,
          isA<NotFoundException>());
    });
  });

  group('MockGroupsRepository — savings goal (Phase 7)', () {
    test('returns the milestone ladder for savings-goal groups', () async {
      final result = await repo.getSavingsGoal('grp_project');

      expect(result.isSuccess, isTrue);
      final goal = result.valueOrNull!;
      expect(goal.targetAmount, const Money(200000));
      expect(goal.targetDate, DateTime(2026, 9, 10));
      expect(goal.milestones, hasLength(4));
      expect(goal.milestones.first.label, '25%');
      expect(goal.milestones.first.amount, const Money(50000));
      expect(goal.milestones.last.percent, 1.0);
    });

    test('fails for non-savings-goal group types', () async {
      final result = await repo.getSavingsGoal('grp_weekend');
      expect(result, isA<Failure<SavingsGoal>>());
      expect((result as Failure<SavingsGoal>).error,
          isA<NotFoundException>());
    });
  });

  group('MockGroupsRepository — business report (Phase 7)', () {
    test('returns the period report for joint-business groups', () async {
      final result = await repo.getBusinessReport('grp_business');

      expect(result.isSuccess, isTrue);
      final report = result.valueOrNull!;
      expect(report.capital, const Money(120000));
      expect(report.revenue, const Money(48000));
      expect(report.expenses, const Money(-31500));
      expect(report.profit, const Money(16500));
      expect(report.recentActivity, hasLength(6));
      expect(report.recentActivity.first.description, 'Week 33 sales');
      expect(report.recentActivity.first.isCredit, isTrue);
      expect(report.recentActivity[1].isCredit, isFalse);
    });

    test('fails for non-joint-business group types', () async {
      final result = await repo.getBusinessReport('grp_weekend');
      expect(result, isA<Failure<BusinessReport>>());
      expect((result as Failure<BusinessReport>).error,
          isA<NotFoundException>());
    });
  });

  group('MockGroupsRepository — governance (spec §20)', () {
    test('returns proposals with vote counts, newest first', () async {
      final result = await repo.getProposals('grp_weekend');

      expect(result.isSuccess, isTrue);
      final proposals = result.valueOrNull!;
      expect(proposals, hasLength(2));
      expect(proposals.first.title, 'Move payout day to Saturday');
      expect(proposals.first.isOpen, isTrue);
      expect(proposals.first.votes['Approve'], 6);
      expect(proposals.first.votes['Decline'], 4);
      expect(proposals.first.totalVotes, 10);
      expect(proposals[1].status, ProposalStatuses.passed);
    });

    test('returns an empty list for groups without proposals', () async {
      final result = await repo.getProposals('grp_project');
      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull, isEmpty);
    });

    test('vote increments the option count and records my vote', () async {
      final result = await repo.voteProposal(
        groupId: 'grp_weekend',
        proposalId: 'prop_1',
        option: 'Approve',
      );

      expect(result.isSuccess, isTrue);
      final proposal = result.valueOrNull!;
      expect(proposal.votes['Approve'], 7);
      expect(proposal.myVote, 'Approve');
      // Persisted for the next read.
      final refreshed = (await repo.getProposals('grp_weekend')).valueOrNull!;
      expect(refreshed.first.votes['Approve'], 7);
      expect(refreshed.first.myVote, 'Approve');
    });

    test('rejects votes on closed proposals, unknown ids and options',
        () async {
      final closed = await repo.voteProposal(
        groupId: 'grp_weekend',
        proposalId: 'prop_2',
        option: 'Approve',
      );
      expect(closed.isFailure, isTrue);
      expect((closed as Failure<GroupProposal>).error,
          isA<ConflictException>());

      final missing = await repo.voteProposal(
        groupId: 'grp_weekend',
        proposalId: 'prop_nope',
        option: 'Approve',
      );
      expect(missing.isFailure, isTrue);
      expect((missing as Failure<GroupProposal>).error,
          isA<NotFoundException>());

      final badOption = await repo.voteProposal(
        groupId: 'grp_weekend',
        proposalId: 'prop_1',
        option: 'Maybe',
      );
      expect(badOption.isFailure, isTrue);
      expect((badOption as Failure<GroupProposal>).error,
          isA<ValidationException>());
    });
  });

  group('MockGroupsRepository — member management (build spec §16)', () {
    test('owner adds a member by phone', () async {
      final result = await repo.addMember(
        groupId: 'grp_weekend',
        identifier: '0209998887',
        actorId: MockGroupsRepository.currentUserId,
      );

      expect(result.isSuccess, isTrue);
      final member = result.valueOrNull!;
      expect(member.fullName, 'Adjoa Asante');
      expect(member.role, GroupRoles.member);

      final members =
          (await repo.getMembers('grp_weekend')).valueOrNull!;
      expect(members.any((m) => m.userId == 'usr_adjoa'), isTrue);
    });

    test('addMember rejects unknown phones and duplicates', () async {
      final unknown = await repo.addMember(
        groupId: 'grp_weekend',
        identifier: '0200000000',
        actorId: MockGroupsRepository.currentUserId,
      );
      expect(unknown.isFailure, isTrue);
      expect((unknown as Failure<GroupMember>).error,
          isA<NotFoundException>());

      // Ama is already a member of Weekend Susu.
      final duplicate = await repo.addMember(
        groupId: 'grp_weekend',
        identifier: '0559876543',
        actorId: MockGroupsRepository.currentUserId,
      );
      expect(duplicate.isFailure, isTrue);
      expect((duplicate as Failure<GroupMember>).error,
          isA<ConflictException>());
    });

    test('addMember requires owner/moderator permission', () async {
      // Kofi is a plain member.
      final result = await repo.addMember(
        groupId: 'grp_weekend',
        identifier: '0209998887',
        actorId: 'usr_kofi',
      );
      expect(result.isFailure, isTrue);
      expect((result as Failure<GroupMember>).error,
          isA<ForbiddenException>());
    });

    test('owner changes a member role', () async {
      final result = await repo.updateMemberRole(
        groupId: 'grp_weekend',
        memberId: 'usr_kofi',
        role: GroupRoles.treasurer,
        actorId: MockGroupsRepository.currentUserId,
      );

      expect(result.isSuccess, isTrue);
      expect(result.valueOrNull!.role, GroupRoles.treasurer);
      final refreshed =
          (await repo.getMembers('grp_weekend')).valueOrNull!;
      expect(
        refreshed.firstWhere((m) => m.userId == 'usr_kofi').role,
        GroupRoles.treasurer,
      );
    });

    test('role changes protect the owner and reject unknown roles', () async {
      final ownerTarget = await repo.updateMemberRole(
        groupId: 'grp_weekend',
        memberId: MockGroupsRepository.currentUserId,
        role: GroupRoles.member,
        actorId: MockGroupsRepository.currentUserId,
      );
      expect(ownerTarget.isFailure, isTrue);
      expect((ownerTarget as Failure<GroupMember>).error,
          isA<ForbiddenException>());

      final badRole = await repo.updateMemberRole(
        groupId: 'grp_weekend',
        memberId: 'usr_kofi',
        role: 'KING',
        actorId: MockGroupsRepository.currentUserId,
      );
      expect(badRole.isFailure, isTrue);
      expect((badRole as Failure<GroupMember>).error,
          isA<ValidationException>());
    });

    test('owner removes a member; self and owner removal are guarded',
        () async {
      final removed = await repo.removeMember(
        groupId: 'grp_weekend',
        memberId: 'usr_nana',
        actorId: MockGroupsRepository.currentUserId,
      );
      expect(removed.isSuccess, isTrue);

      final self = await repo.removeMember(
        groupId: 'grp_weekend',
        memberId: MockGroupsRepository.currentUserId,
        actorId: MockGroupsRepository.currentUserId,
      );
      expect(self.isFailure, isTrue);
      expect((self as Failure<void>).error, isA<ValidationException>());

      // Restore Nana, then try to remove the owner as a moderator.
      await repo.addMember(
        groupId: 'grp_weekend',
        identifier: '0243334445',
        actorId: MockGroupsRepository.currentUserId,
      );
      final owner = await repo.removeMember(
        groupId: 'grp_weekend',
        memberId: MockGroupsRepository.currentUserId,
        actorId: 'usr_ama',
      );
      expect(owner.isFailure, isTrue);
      expect((owner as Failure<void>).error, isA<ForbiddenException>());
    });
  });
}
