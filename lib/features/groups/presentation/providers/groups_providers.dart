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

/// Group members.
final groupMembersProvider =
    FutureProvider.family<List<GroupMember>, String>((ref, groupId) async {
  final result = await ref.read(groupsRepositoryProvider).getMembers(groupId);
  return switch (result) {
    Success<List<GroupMember>>(:final value) => value,
    Failure<List<GroupMember>>(:final error) => throw error,
  };
});

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
