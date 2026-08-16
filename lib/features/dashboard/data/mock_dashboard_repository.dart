import '../../../core/utils/result.dart';
import '../../../shared/models/money.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';

/// Deterministic mock dashboard data matching the design reference
/// (spec §11): Kwame Owusu, balance GHS 1,250.00, three active susu groups,
/// recent transactions, unread notifications.
class MockDashboardRepository implements DashboardRepository {
  static final DashboardSummary _summary = DashboardSummary(
    totalBalance: const Money(125000),
    activeGroups: <DashboardGroup>[
      DashboardGroup(
        id: 'grp_weekend',
        name: 'Weekend Susu',
        pot: const Money(50000),
        memberCount: 10,
        totalMembers: 10,
        myContribution: const Money(5000),
        myTarget: const Money(10000),
        nextPayout: DateTime(2026, 8, 25),
      ),
      DashboardGroup(
        id: 'grp_project',
        name: 'Project Susu',
        pot: const Money(75000),
        memberCount: 15,
        totalMembers: 15,
        myContribution: const Money(10000),
        myTarget: const Money(30000),
        nextPayout: DateTime(2026, 9, 10),
      ),
      DashboardGroup(
        id: 'grp_business',
        name: 'Business Susu',
        pot: const Money(120000),
        memberCount: 20,
        totalMembers: 20,
        myContribution: const Money(5000),
        myTarget: const Money(20000),
        nextPayout: DateTime(2026, 10, 5),
      ),
    ],
    recentTransactions: <DashboardTransaction>[
      DashboardTransaction(
        id: 'txn_1',
        type: 'CONTRIBUTION',
        description: 'Weekend Susu contribution',
        amount: const Money(-5000),
        timestamp: DateTime(2026, 8, 14, 9, 30),
      ),
      DashboardTransaction(
        id: 'txn_2',
        type: 'DEPOSIT',
        description: 'Wallet top-up',
        amount: const Money(20000),
        timestamp: DateTime(2026, 8, 13, 18, 5),
      ),
      DashboardTransaction(
        id: 'txn_3',
        type: 'WITHDRAWAL',
        description: 'Wallet withdrawal',
        amount: const Money(-30000),
        timestamp: DateTime(2026, 8, 12, 12, 45),
      ),
      DashboardTransaction(
        id: 'txn_4',
        type: 'CONTRIBUTION',
        description: 'Project Susu contribution',
        amount: const Money(-5000),
        timestamp: DateTime(2026, 8, 11, 8, 20),
      ),
    ],
    unreadNotifications: 3,
  );

  @override
  Future<Result<DashboardSummary>> getSummary() async =>
      Success<DashboardSummary>(_summary);
}
