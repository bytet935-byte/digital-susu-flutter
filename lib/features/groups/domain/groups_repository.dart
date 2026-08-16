import '../../../core/utils/result.dart';
import '../../../shared/models/money.dart';
import 'group_models.dart';

/// Groups contract (spec §6, §14; build spec §8–§10).
abstract interface class GroupsRepository {
  Future<Result<List<SusuGroup>>> getMyGroups();

  Future<Result<SusuGroup>> getGroup(String groupId);

  Future<Result<SusuGroup>> createGroup({
    required String name,
    required String type,
    String? description,
  });

  Future<Result<SusuGroup>> joinGroup(String inviteCode);

  Future<Result<List<GroupMember>>> getMembers(String groupId);

  Future<Result<List<GroupMessage>>> getMessages(String groupId);

  Future<Result<GroupMessage>> sendMessage({
    required String groupId,
    required String body,
    required String senderId,
    required String senderName,
  });

  /// Records a contribution to the group pot (spec §9, Phase 6).
  Future<Result<GroupContribution>> contribute({
    required String groupId,
    required Money amount,
    required String paymentMethod,
    required String idempotencyKey,
  });

  /// Invite code used by the join-by-code flow (design reference Invite).
  Future<Result<String>> getInviteCode(String groupId);

  /// Payout schedule for rotational susu groups (Phase 7); other group
  /// types fail with a "no schedule" error and the UI hides the card.
  Future<Result<SusuSchedule>> getPayoutSchedule(String groupId);

  /// Savings goal for savings-goal groups (Phase 7); other group types
  /// fail and the UI hides the card.
  Future<Result<SavingsGoal>> getSavingsGoal(String groupId);

  /// Period report for joint-business groups (Phase 7); other group types
  /// fail and the UI hides the card.
  Future<Result<BusinessReport>> getBusinessReport(String groupId);

  /// Governance proposals for a group (spec §20); empty list when none.
  Future<Result<List<GroupProposal>>> getProposals(String groupId);

  /// Records the current user's vote; returns the updated proposal.
  Future<Result<GroupProposal>> voteProposal({
    required String groupId,
    required String proposalId,
    required String option,
  });

  /// Adds a member by phone/email identifier (build spec §16). Requires
  /// owner/moderator permission (via [actorId]).
  Future<Result<GroupMember>> addMember({
    required String groupId,
    required String identifier,
    required String actorId,
  });

  /// Updates a member's role (MEMBER / TREASURER / MODERATOR / ADMIN).
  Future<Result<GroupMember>> updateMemberRole({
    required String groupId,
    required String memberId,
    required String role,
    required String actorId,
  });

  /// Removes a member from the group.
  Future<Result<void>> removeMember({
    required String groupId,
    required String memberId,
    required String actorId,
  });
}
