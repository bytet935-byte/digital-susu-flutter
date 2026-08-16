import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../../../shared/models/money.dart';
import '../domain/group_models.dart';
import '../domain/groups_repository.dart';

/// Real-backend groups repository (spec §11, §23).
class ApiGroupsRepository implements GroupsRepository {
  ApiGroupsRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<List<SusuGroup>>> getMyGroups() async {
    try {
      final data = await _client.getMap(ApiEndpoints.groups);
      final groups = (data['groups'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(_mapGroup)
          .toList();
      return Success<List<SusuGroup>>(groups);
    } on AppException catch (error) {
      return Failure<List<SusuGroup>>(error);
    }
  }

  @override
  Future<Result<SusuGroup>> getGroup(String groupId) async {
    try {
      final data = await _client.getMap(ApiEndpoints.group(groupId));
      return Success<SusuGroup>(_mapGroup(data));
    } on AppException catch (error) {
      return Failure<SusuGroup>(error);
    }
  }

  @override
  Future<Result<SusuGroup>> createGroup({
    required String name,
    required String type,
    String? description,
  }) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.groups,
        data: <String, dynamic>{
          'name': name,
          'type': type,
          if (description != null && description.isNotEmpty)
            'description': description,
        },
      );
      return Success<SusuGroup>(_mapGroup(data));
    } on AppException catch (error) {
      return Failure<SusuGroup>(error);
    }
  }

  @override
  Future<Result<SusuGroup>> joinGroup(String inviteCode) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.groups,
        data: <String, dynamic>{'invite_code': inviteCode},
      );
      return Success<SusuGroup>(_mapGroup(data));
    } on AppException catch (error) {
      return Failure<SusuGroup>(error);
    }
  }

  @override
  Future<Result<List<GroupMember>>> getMembers(String groupId) async {
    try {
      final data = await _client.getMap(ApiEndpoints.groupMembers(groupId));
      final members = (data['members'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(GroupMember.fromJson)
          .toList();
      return Success<List<GroupMember>>(members);
    } on AppException catch (error) {
      return Failure<List<GroupMember>>(error);
    }
  }

  @override
  Future<Result<List<GroupMessage>>> getMessages(String groupId) async {
    try {
      final data = await _client.getList(ApiEndpoints.groupMessages(groupId));
      final messages = data
          .whereType<Map<String, dynamic>>()
          .map(GroupMessage.fromJson)
          .toList();
      return Success<List<GroupMessage>>(messages);
    } on AppException catch (error) {
      return Failure<List<GroupMessage>>(error);
    }
  }

  @override
  Future<Result<GroupMessage>> sendMessage({
    required String groupId,
    required String body,
    required String senderId,
    required String senderName,
  }) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.groupMessages(groupId),
        data: <String, dynamic>{
          'body': body,
          'sender_id': senderId,
          'sender_name': senderName,
        },
      );
      return Success<GroupMessage>(GroupMessage.fromJson(data));
    } on AppException catch (error) {
      return Failure<GroupMessage>(error);
    }
  }

  @override
  Future<Result<GroupContribution>> contribute({
    required String groupId,
    required Money amount,
    required String paymentMethod,
    required String idempotencyKey,
  }) async {
    try {
      final data = await _client.postMap(
        ApiEndpoints.groupContributions(groupId),
        data: <String, dynamic>{
          'amount_minor': amount.amountMinor,
          'payment_method': paymentMethod,
          'idempotency_key': idempotencyKey,
        },
      );
      final id = data['id'];
      final amountMinor = data['amount_minor'];
      if (id is! String || amountMinor is! int) {
        throw const MalformedResponseException();
      }
      final createdAt = data['created_at'];
      return Success<GroupContribution>(
        GroupContribution(
          id: id,
          groupId: groupId,
          amount: Money(amountMinor),
          paymentMethod: paymentMethod,
          timestamp: createdAt is String
              ? DateTime.tryParse(createdAt) ?? DateTime.now()
              : DateTime.now(),
        ),
      );
    } on AppException catch (error) {
      return Failure<GroupContribution>(error);
    }
  }

  @override
  Future<Result<String>> getInviteCode(String groupId) async {
    try {
      final data = await _client.getMap(ApiEndpoints.group(groupId));
      final code = data['invite_code'];
      if (code is String && code.isNotEmpty) return Success<String>(code);
      // Stable derived fallback until the server returns invite_code.
      return Success<String>('G${groupId.toUpperCase()}');
    } on AppException catch (error) {
      return Failure<String>(error);
    }
  }

  @override
  Future<Result<SusuSchedule>> getPayoutSchedule(String groupId) async {
    // A dedicated susu-systems endpoint lands with the backend Phase 7
    // work; until then the card stays hidden in API mode.
    return const Failure<SusuSchedule>(
      NotFoundException(
        message: 'Payout schedules are not available in API mode yet.',
      ),
    );
  }

  @override
  Future<Result<SavingsGoal>> getSavingsGoal(String groupId) async {
    // A dedicated susu-systems endpoint lands with the backend Phase 7
    // work; until then the card stays hidden in API mode.
    return const Failure<SavingsGoal>(
      NotFoundException(
        message: 'Savings goals are not available in API mode yet.',
      ),
    );
  }

  /// Maps a server group payload (wallet/contribution fields aggregated by
  /// the backend) onto the app's SusuGroup model.
  SusuGroup _mapGroup(Map<String, dynamic> json) {
    final members = json['member_count'] as num?;
    return SusuGroup(
      id: json['id'] as String,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? GroupTypes.rotationalSusu,
      status: json['status'] as String? ?? GroupStatuses.active,
      pot: Money.fromMajor((json['pot'] as num?)?.toDouble() ?? 0),
      memberCount: members?.toInt() ?? 0,
      totalMembers: members?.toInt() ?? 0,
      description: json['description'] as String? ?? '',
      nextPayout: json['next_payout'] is String
          ? DateTime.tryParse(json['next_payout'] as String)
          : null,
      currency: json['currency'] as String? ?? 'GHS',
    );
  }
}
