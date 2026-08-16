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

/// Rotational susu payout schedule (Phase 7): cycle progress, contribution
/// per cycle, the next payout and the upcoming rotation order.
class SusuSchedule extends Equatable {
  const SusuSchedule({
    required this.cycleNumber,
    required this.totalCycles,
    required this.frequencyLabel,
    required this.contributionPerCycle,
    required this.payoutAmount,
    required this.upcomingPayouts,
  });

  final int cycleNumber;
  final int totalCycles;

  /// e.g. `Weekly`, `Fortnightly`, `Monthly`.
  final String frequencyLabel;
  final Money contributionPerCycle;
  final Money payoutAmount;

  /// Sorted by date; the first entry is the next payout.
  final List<PayoutTurn> upcomingPayouts;

  double get progress => totalCycles <= 0
      ? 0
      : (cycleNumber / totalCycles).clamp(0.0, 1.0);

  @override
  List<Object?> get props => <Object?>[
        cycleNumber,
        totalCycles,
        frequencyLabel,
        contributionPerCycle,
        payoutAmount,
        upcomingPayouts,
      ];
}

/// One payout turn in the rotation (Phase 7).
class PayoutTurn extends Equatable {
  const PayoutTurn({
    required this.memberName,
    required this.date,
    required this.amount,
  });

  final String memberName;
  final DateTime date;
  final Money amount;

  @override
  List<Object?> get props => <Object?>[memberName, date, amount];
}

/// Savings-goal group plan (Phase 7): target pot, target date and the
/// milestone ladder. Reached-state is derived from the group pot at render
/// time (pot >= milestone.amount).
class SavingsGoal extends Equatable {
  const SavingsGoal({
    required this.targetAmount,
    this.targetDate,
    required this.milestones,
  });

  final Money targetAmount;
  final DateTime? targetDate;
  final List<GoalMilestone> milestones;

  @override
  List<Object?> get props => <Object?>[targetAmount, targetDate, milestones];
}

/// One milestone on the goal ladder (Phase 7).
class GoalMilestone extends Equatable {
  const GoalMilestone({
    required this.label,
    required this.percent,
    required this.amount,
  });

  final String label;

  /// 0.0–1.0 position on the bar (25% / 50% / 75% / 100%).
  final double percent;
  final Money amount;

  @override
  List<Object?> get props => <Object?>[label, percent, amount];
}

/// Joint-business period report (Phase 7): committed capital, revenue and
/// expenses for the period, plus the latest business activity.
class BusinessReport extends Equatable {
  const BusinessReport({
    required this.capital,
    required this.revenue,
    required this.expenses,
    required this.recentActivity,
  });

  final Money capital;

  /// Credits this period (sales, service income, …).
  final Money revenue;

  /// Debits this period (stock, logistics, marketing, …) — negative.
  final Money expenses;
  final List<BusinessEntry> recentActivity;

  /// Expenses are stored negative, so profit is revenue + expenses.
  Money get profit => revenue + expenses;

  @override
  List<Object?> get props =>
      <Object?>[capital, revenue, expenses, recentActivity];
}

/// One business activity entry (Phase 7).
class BusinessEntry extends Equatable {
  const BusinessEntry({
    required this.description,
    required this.amount,
    required this.timestamp,
  });

  final String description;

  /// Negative for expenses.
  final Money amount;
  final DateTime timestamp;

  bool get isCredit => amount.amountMinor >= 0;

  @override
  List<Object?> get props => <Object?>[description, amount, timestamp];
}

/// Proposal statuses (spec §20, build spec §16).
abstract final class ProposalStatuses {
  static const String open = 'OPEN';
  static const String passed = 'PASSED';
  static const String rejected = 'REJECTED';
}

/// A governance proposal with per-option vote counts (spec §20, build
/// spec §16; backend `GET/POST /groups/:id/proposals`).
class GroupProposal extends Equatable {
  const GroupProposal({
    required this.id,
    required this.groupId,
    required this.title,
    this.description = '',
    required this.status,
    required this.options,
    this.votes = const <String, int>{},
    this.result,
    this.votingEnds,
    required this.createdAt,
    this.createdByName,
    this.myVote,
  });

  final String id;
  final String groupId;
  final String title;
  final String description;
  final String status;

  /// Vote options, e.g. `['Approve', 'Decline']`.
  final List<String> options;
  final Map<String, int> votes;

  /// Winning option once voting closes.
  final String? result;
  final DateTime? votingEnds;
  final DateTime createdAt;
  final String? createdByName;

  /// The current user's vote option, when they have voted.
  final String? myVote;

  bool get isOpen => status == ProposalStatuses.open;

  int get totalVotes => votes.values.fold(0, (int sum, int count) => sum + count);

  GroupProposal copyWith({
    String? status,
    Map<String, int>? votes,
    String? result,
    String? myVote,
  }) =>
      GroupProposal(
        id: id,
        groupId: groupId,
        title: title,
        description: description,
        status: status ?? this.status,
        options: options,
        votes: votes ?? this.votes,
        result: result ?? this.result,
        votingEnds: votingEnds,
        createdAt: createdAt,
        createdByName: createdByName,
        myVote: myVote ?? this.myVote,
      );

  factory GroupProposal.fromJson(Map<String, dynamic> json) => GroupProposal(
        id: json['id'] as String,
        groupId: json['group_id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: json['status'] as String? ?? ProposalStatuses.open,
        options: (json['options'] as List<dynamic>? ?? <dynamic>[])
            .map((Object? o) => o.toString())
            .toList(),
        votes: json['votes'] is Map<String, dynamic>
            ? (json['votes'] as Map<String, dynamic>).map(
                (String k, Object? v) => MapEntry<String, int>(
                  k,
                  v is int ? v : 0,
                ),
              )
            : const <String, int>{},
        result: json['result'] as String?,
        votingEnds: json['voting_ends'] is String
            ? DateTime.tryParse(json['voting_ends'] as String)
            : null,
        createdAt: json['created_at'] is String
            ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
            : DateTime.now(),
        createdByName: json['created_by_name'] as String?,
        myVote: json['my_vote'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        groupId,
        title,
        description,
        status,
        options,
        votes,
        result,
        votingEnds,
        createdAt,
        createdByName,
        myVote,
      ];
}
