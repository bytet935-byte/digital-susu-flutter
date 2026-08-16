import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/api_groups_repository.dart';
import '../../data/mock_groups_repository.dart';
import '../../domain/group_models.dart';
import '../../domain/groups_repository.dart';
/// Switches mock/API via USE_MOCK_DATA (spec §11).
final groupsRepositoryProvider = Provider<GroupsRepository>((ref) {
  return selectRepository<GroupsRepository>(
    mock: MockGroupsRepository(),
    api: ApiGroupsRepository(ref.watch(apiClientProvider)),
  );
});

/// The user's groups (FLOW 2/3); supports create and join which refresh the
/// list.
final myGroupsProvider = AsyncNotifierProvider<MyGroupsController, List<SusuGroup>>(
  MyGroupsController.new,
);

class MyGroupsController extends AsyncNotifier<List<SusuGroup>> {
  GroupsRepository get _repo => ref.read(groupsRepositoryProvider);

  @override
  Future<List<SusuGroup>> build() => _fetch();

  Future<List<SusuGroup>> _fetch() async {
    final result = await _repo.getMyGroups();
    return switch (result) {
      Success<List<SusuGroup>>(:final value) => value,
      Failure<List<SusuGroup>>(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }

  /// Creates a group and refreshes the list (spec §14 validation happens in
  /// the repository/screen).
  Future<SusuGroup> createGroup({
    required String name,
    required String type,
    String? description,
  }) async {
    final result = await _repo.createGroup(
      name: name,
      type: type,
      description: description,
    );
    final group = switch (result) {
      Success<SusuGroup>(:final value) => value,
      Failure<SusuGroup>(:final error) => throw error,
    };
    await refresh();
    return group;
  }

  /// Joins a group by invite code (FLOW 3) and refreshes the list.
  Future<SusuGroup> joinGroup(String inviteCode) async {
    final result = await _repo.joinGroup(inviteCode);
    final group = switch (result) {
      Success<SusuGroup>(:final value) => value,
      Failure<SusuGroup>(:final error) => throw error,
    };
    await refresh();
    return group;
  }
}

/// Group details for the details screen.
final groupDetailsProvider =
    FutureProvider.family<SusuGroup, String>((ref, groupId) async {
  final result = await ref.read(groupsRepositoryProvider).getGroup(groupId);
  return switch (result) {
    Success<SusuGroup>(:final value) => value,
    Failure<SusuGroup>(:final error) => throw error,
  };
});

/// Invite code per group (design reference Invite quick action).
final inviteCodeProvider =
    FutureProvider.family<String, String>((ref, groupId) async {
  final result = await ref.read(groupsRepositoryProvider).getInviteCode(groupId);
  return switch (result) {
    Success<String>(:final value) => value,
    Failure<String>(:final error) => throw error,
  };
});

/// Payout schedule for rotational groups (Phase 7); fails gracefully for
/// other group types and in API mode (card hidden).
final payoutScheduleProvider =
    FutureProvider.family<SusuSchedule, String>((ref, groupId) async {
  final result =
      await ref.read(groupsRepositoryProvider).getPayoutSchedule(groupId);
  return switch (result) {
    Success<SusuSchedule>(:final value) => value,
    Failure<SusuSchedule>(:final error) => throw error,
  };
});

/// Savings goal for savings-goal groups (Phase 7); fails gracefully for
/// other group types and in API mode (card hidden).
final savingsGoalProvider =
    FutureProvider.family<SavingsGoal, String>((ref, groupId) async {
  final result = await ref.read(groupsRepositoryProvider).getSavingsGoal(groupId);
  return switch (result) {
    Success<SavingsGoal>(:final value) => value,
    Failure<SavingsGoal>(:final error) => throw error,
  };
});

/// Joint-business period report (Phase 7); fails gracefully for other
/// group types and in API mode (card hidden).
final businessReportProvider =
    FutureProvider.family<BusinessReport, String>((ref, groupId) async {
  final result =
      await ref.read(groupsRepositoryProvider).getBusinessReport(groupId);
  return switch (result) {
    Success<BusinessReport>(:final value) => value,
    Failure<BusinessReport>(:final error) => throw error,
  };
});

/// Governance proposals per group (spec §20); voting updates the list.
final groupProposalsProvider =
    AsyncNotifierProvider.family<ProposalsController, List<GroupProposal>, String>(
  ProposalsController.new,
);

class ProposalsController extends FamilyAsyncNotifier<List<GroupProposal>, String> {
  @override
  Future<List<GroupProposal>> build(String groupId) => _fetch(groupId);

  Future<List<GroupProposal>> _fetch(String groupId) async {
    final result = await ref.read(groupsRepositoryProvider).getProposals(groupId);
    return switch (result) {
      Success<List<GroupProposal>>(:final value) => value,
      Failure<List<GroupProposal>>(:final error) => throw error,
    };
  }

  /// Returns `true` on success so the UI can confirm with a snackbar.
  Future<bool> vote({
    required String groupId,
    required String proposalId,
    required String option,
  }) async {
    final result = await ref.read(groupsRepositoryProvider).voteProposal(
          groupId: groupId,
          proposalId: proposalId,
          option: option,
        );
    return switch (result) {
      Success<GroupProposal>(:final value) => _apply(updated: value),
      Failure<GroupProposal>() => false,
    };
  }

  bool _apply({required GroupProposal updated}) {
    final current = state.valueOrNull ?? <GroupProposal>[];
    state = AsyncData<List<GroupProposal>>(
      current.map((GroupProposal p) => p.id == updated.id ? updated : p).toList(),
    );
    return true;
  }
}

/// Group members with add/role/remove actions (build spec §16).
final groupMembersProvider =
    AsyncNotifierProvider.family<MembersController, List<GroupMember>, String>(
  MembersController.new,
);

class MembersController extends FamilyAsyncNotifier<List<GroupMember>, String> {
  @override
  Future<List<GroupMember>> build(String groupId) => _fetch(groupId);

  Future<List<GroupMember>> _fetch(String groupId) async {
    final result = await ref.read(groupsRepositoryProvider).getMembers(groupId);
    return switch (result) {
      Success<List<GroupMember>>(:final value) => value,
      Failure<List<GroupMember>>(:final error) => throw error,
    };
  }

  /// Mutations return `null` on success or the error message to show.
  /// State is rebuilt from the repository after each mutation so the list
  /// always mirrors the source of truth.
  Future<String?> addMember({
    required String groupId,
    required String identifier,
    required String actorId,
  }) async {
    final result = await ref.read(groupsRepositoryProvider).addMember(
          groupId: groupId,
          identifier: identifier,
          actorId: actorId,
        );
    return switch (result) {
      Success<GroupMember>() => _refetch(groupId),
      Failure<GroupMember>(:final error) => error.message,
    };
  }

  Future<String?> updateRole({
    required String groupId,
    required String memberId,
    required String role,
    required String actorId,
  }) async {
    final result = await ref.read(groupsRepositoryProvider).updateMemberRole(
          groupId: groupId,
          memberId: memberId,
          role: role,
          actorId: actorId,
        );
    return switch (result) {
      Success<GroupMember>() => _refetch(groupId),
      Failure<GroupMember>(:final error) => error.message,
    };
  }

  Future<String?> removeMember({
    required String groupId,
    required String memberId,
    required String actorId,
  }) async {
    final result = await ref.read(groupsRepositoryProvider).removeMember(
          groupId: groupId,
          memberId: memberId,
          actorId: actorId,
        );
    return switch (result) {
      Success<void>() => _refetch(groupId),
      Failure<void>(:final error) => error.message,
    };
  }

  Future<String?> _refetch(String groupId) async {
    state = await AsyncValue.guard(() => _fetch(groupId));
    return null;
  }
}

/// Group chat messages with a send action (build spec §10).
final groupMessagesProvider = AsyncNotifierProvider.family<
    GroupMessagesController, List<GroupMessage>, String>(
  GroupMessagesController.new,
);

class GroupMessagesController extends FamilyAsyncNotifier<List<GroupMessage>, String> {
  GroupsRepository get _repo => ref.read(groupsRepositoryProvider);

  @override
  Future<List<GroupMessage>> build(String groupId) => _fetch(groupId);

  Future<List<GroupMessage>> _fetch(String groupId) async {
    final result = await _repo.getMessages(groupId);
    return switch (result) {
      Success<List<GroupMessage>>(:final value) => value,
      Failure<List<GroupMessage>>(:final error) => throw error,
    };
  }

  /// Sends a message and appends it to the local list (server confirmations
  /// land in the real backend; mock appends immediately).
  Future<void> send({
    required String groupId,
    required String body,
    required String senderId,
    required String senderName,
  }) async {
    final result = await _repo.sendMessage(
      groupId: groupId,
      body: body,
      senderId: senderId,
      senderName: senderName,
    );
    final message = switch (result) {
      Success<GroupMessage>(:final value) => value,
      Failure<GroupMessage>(:final error) => throw error,
    };
    final current = state.valueOrNull ?? <GroupMessage>[];
    state = AsyncData(<GroupMessage>[message, ...current]);
  }
}
