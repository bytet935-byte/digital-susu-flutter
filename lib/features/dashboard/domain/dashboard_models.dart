import 'package:equatable/equatable.dart';

import '../../../shared/models/money.dart';

/// Permission-aware dashboard summary (spec §13).
///
/// The backend filters this payload by the requesting user's effective
/// permissions; the client renders exactly what it receives — financial
/// information the user may not see is never transmitted in the first place.
class DashboardSummary extends Equatable {
  const DashboardSummary({
    required this.totalBalance,
    required this.activeGroups,
    required this.recentTransactions,
    this.unreadNotifications = 0,
  });

  final Money totalBalance;
  final List<DashboardGroup> activeGroups;
  final List<DashboardTransaction> recentTransactions;
  final int unreadNotifications;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) =>
      DashboardSummary(
        totalBalance: Money.fromMajor(
          (json['total_balance'] as num?)?.toDouble() ?? 0,
        ),
        activeGroups: (json['active_groups'] as List<dynamic>? ?? const [])
            .whereType<Map<String, dynamic>>()
            .map(DashboardGroup.fromJson)
            .toList(),
        recentTransactions:
            (json['recent_transactions'] as List<dynamic>? ?? const [])
                .whereType<Map<String, dynamic>>()
                .map(DashboardTransaction.fromJson)
                .toList(),
        unreadNotifications: json['unread_notifications'] as int? ?? 0,
      );

  @override
  List<Object?> get props =>
      <Object?>[totalBalance, activeGroups, recentTransactions, unreadNotifications];
}

/// Light projection of a susu group for the dashboard/list views.
class DashboardGroup extends Equatable {
  const DashboardGroup({
    required this.id,
    required this.name,
    required this.pot,
    required this.memberCount,
    required this.totalMembers,
    required this.myContribution,
    required this.myTarget,
    this.nextPayout,
    this.status = 'ACTIVE',
  });

  final String id;
  final String name;

  /// Current total pot of the group.
  final Money pot;
  final int memberCount;
  final int totalMembers;
  final Money myContribution;
  final Money myTarget;
  final DateTime? nextPayout;

  /// ACTIVE / COMPLETED.
  final String status;

  /// Contribution progress 0..1 (never exceeds 1).
  double get progress {
    final target = myTarget.amountMinor;
    if (target <= 0) return 0;
    return (myContribution.amountMinor / target).clamp(0.0, 1.0);
  }

  factory DashboardGroup.fromJson(Map<String, dynamic> json) => DashboardGroup(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        pot: Money.fromMajor((json['pot'] as num?)?.toDouble() ?? 0),
        memberCount: json['member_count'] as int? ?? 0,
        totalMembers: json['total_members'] as int? ?? 0,
        myContribution: Money.fromMajor(
            (json['my_contribution'] as num?)?.toDouble() ?? 0),
        myTarget:
            Money.fromMajor((json['my_target'] as num?)?.toDouble() ?? 0),
        nextPayout: json['next_payout'] is String
            ? DateTime.tryParse(json['next_payout'] as String)
            : null,
        status: json['status'] as String? ?? 'ACTIVE',
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        name,
        pot,
        memberCount,
        totalMembers,
        myContribution,
        myTarget,
        nextPayout,
        status,
      ];
}

/// Light transaction projection for the dashboard (full ledger in Phase 6).
class DashboardTransaction extends Equatable {
  const DashboardTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.timestamp,
    this.status = 'SUCCESSFUL',
  });

  final String id;

  /// CONTRIBUTION / DEPOSIT / WITHDRAWAL / PAYOUT / ...
  final String type;
  final String description;

  /// Negative = debit, positive = credit.
  final Money amount;
  final DateTime timestamp;
  final String status;

  bool get isCredit => amount.amountMinor >= 0;

  factory DashboardTransaction.fromJson(Map<String, dynamic> json) =>
      DashboardTransaction(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'TRANSACTION',
        description: json['description'] as String? ?? '',
        amount: Money.fromMajor((json['amount'] as num?)?.toDouble() ?? 0),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        status: json['status'] as String? ?? 'SUCCESSFUL',
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        type,
        description,
        amount,
        timestamp,
        status,
      ];
}
