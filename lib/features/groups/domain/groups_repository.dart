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
}
