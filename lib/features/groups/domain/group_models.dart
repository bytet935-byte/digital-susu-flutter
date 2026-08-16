import 'package:equatable/equatable.dart';

import '../../../shared/models/money.dart';

/// Susu group types (spec §6).
abstract final class GroupTypes {
  static const String rotationalSusu = 'ROTATIONAL_SUSU';
  static const String savingsGoal = 'SAVINGS_GOAL';
  static const String jointBusiness = 'JOINT_BUSINESS';

  /// All supported group types, in UI order.
  static const List<String> values = <String>[
    rotationalSusu,
    savingsGoal,
    jointBusiness,
  ];

  static String label(String type) => switch (type) {
        rotationalSusu => 'Rotational Susu',
        savingsGoal => 'Savings Goal',
        jointBusiness => 'Joint Business',
        _ => 'Susu Group',
      };
}

/// Group lifecycle statuses (build spec §8).
abstract final class GroupStatuses {
  static const String active = 'ACTIVE';
  static const String upcoming = 'UPCOMING';
  static const String completed = 'COMPLETED';
  static const String pending = 'PENDING';
  static const String paused = 'PAUSED';

  static const List<String> all = <String>[
    active,
    upcoming,
    completed,
    pending,
    paused,
  ];
}

/// Group member roles (spec §5).
abstract final class GroupRoles {
  static const String owner = 'GROUP_OWNER';
  static const String admin = 'ADMIN';
  static const String treasurer = 'TREASURER';
  static const String moderator = 'MODERATOR';
  static const String member = 'MEMBER';

  static String label(String role) => switch (role) {
        owner => 'Owner',
        admin => 'Admin',
        treasurer => 'Treasurer',
        moderator => 'Moderator',
        _ => 'Member',
      };
}

/// A susu group (spec §6, build spec §8).
class SusuGroup extends Equatable {
  const SusuGroup({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.pot,
    required this.memberCount,
    required this.totalMembers,
    this.description = '',
    this.nextPayout,
    this.currency = 'GHS',
    this.myContribution = const Money(0),
    this.myTarget,
  });

  final String id;
  final String name;
  final String type;
  final String status;

  /// Current total pot (group wallet projection).
  final Money pot;
  final int memberCount;
  final int totalMembers;
  final String description;
  final DateTime? nextPayout;
  final String currency;

  /// My contributed amount so far (design reference screen 8 progress bar).
  final Money myContribution;

  /// My contribution target for the current cycle; `null` hides the bar.
  final Money? myTarget;

  bool get isActive => status == GroupStatuses.active;

  factory SusuGroup.fromJson(Map<String, dynamic> json) => SusuGroup(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        type: json['type'] as String? ?? GroupTypes.rotationalSusu,
        status: json['status'] as String? ?? GroupStatuses.active,
        pot: Money.fromMajor((json['pot'] as num?)?.toDouble() ?? 0),
        memberCount: json['member_count'] as int? ?? 0,
        totalMembers: json['total_members'] as int? ?? 0,
        description: json['description'] as String? ?? '',
        nextPayout: json['next_payout'] is String
            ? DateTime.tryParse(json['next_payout'] as String)
            : null,
        currency: json['currency'] as String? ?? 'GHS',
        myContribution: json['my_contribution'] is int
            ? Money(json['my_contribution'] as int)
            : const Money(0),
        myTarget: json['my_target'] is int
            ? Money(json['my_target'] as int)
            : null,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        type,
        status,
        pot,
        memberCount,
        totalMembers,
        description,
        nextPayout,
        currency,
        myContribution,
        myTarget,
      ];
}

/// Group membership record (spec §14, build spec §9).
class GroupMember extends Equatable {
  const GroupMember({
    required this.userId,
    required this.fullName,
    required this.phone,
    required this.role,
  });

  final String userId;
  final String fullName;
  final String phone;
  final String role;

  factory GroupMember.fromJson(Map<String, dynamic> json) => GroupMember(
        userId: json['user_id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        role: json['role'] as String? ?? GroupRoles.member,
      );

  @override
  List<Object?> get props => <Object?>[userId, fullName, phone, role];
}

/// Group chat message (build spec §10).
class GroupMessage extends Equatable {
  const GroupMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String senderId;
  final String senderName;
  final String body;
  final DateTime createdAt;

  /// Whether the message belongs to the current user (computed in UI).
  bool isMine(String currentUserId) => senderId == currentUserId;

  factory GroupMessage.fromJson(Map<String, dynamic> json) => GroupMessage(
        id: json['id'] as String,
        senderId: json['sender_id'] as String,
        senderName: json['sender_name'] as String? ?? '',
        body: json['body'] as String? ?? '',
        createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  @override
  List<Object?> get props => <Object?>[id, senderId, senderName, body, createdAt];
}

/// A recorded group contribution receipt (spec §9, Phase 6).
class GroupContribution extends Equatable {
  const GroupContribution({
    required this.id,
    required this.groupId,
    required this.amount,
    required this.paymentMethod,
    required this.timestamp,
  });

  final String id;
  final String groupId;
  final Money amount;

  /// `MOBILE_MONEY` | `CARD` (spec §9).
  final String paymentMethod;
  final DateTime timestamp;

  @override
  List<Object?> get props =>
      <Object?>[id, groupId, amount, paymentMethod, timestamp];
}
