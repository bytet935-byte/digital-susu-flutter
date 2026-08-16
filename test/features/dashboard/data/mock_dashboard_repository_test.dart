import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/dashboard/data/mock_dashboard_repository.dart';

void main() {
  group('MockDashboardRepository (design reference data)', () {
    test('returns Kwame balance GHS 1,250.00 and three active groups', () async {
      final result = await MockDashboardRepository().getSummary();
      final summary = result.valueOrNull;
      expect(summary, isNotNull);
      expect(summary!.totalBalance.amountMinor, 125000); // GHS 1,250.00
      expect(summary.activeGroups, hasLength(3));
      expect(summary.unreadNotifications, 3);
    });

    test('group names and pots match the design reference', () async {
      final summary =
          (await MockDashboardRepository().getSummary()).valueOrNull!;
      final names = summary.activeGroups.map((g) => g.name).toList();
      expect(names, <String>['Weekend Susu', 'Project Susu', 'Business Susu']);
      expect(summary.activeGroups.first.pot.amountMinor, 50000); // GHS 500
    });

    test('group progress is clamped to 0..1', () async {
      final summary =
          (await MockDashboardRepository().getSummary()).valueOrNull!;
      final weekend = summary.activeGroups.first;
      expect(weekend.progress, closeTo(0.5, 0.001)); // 50 / 100
      for (final group in summary.activeGroups) {
        expect(group.progress, inInclusiveRange(0, 1));
      }
    });

    test('recent transactions include credit and debit amounts', () async {
      final summary =
          (await MockDashboardRepository().getSummary()).valueOrNull!;
      expect(summary.recentTransactions, hasLength(4));
      expect(summary.recentTransactions.first.isCredit, isFalse);
      final deposit =
          summary.recentTransactions.firstWhere((t) => t.type == 'DEPOSIT');
      expect(deposit.isCredit, isTrue);
      expect(deposit.amount.amountMinor, 20000);
    });
  });
}
