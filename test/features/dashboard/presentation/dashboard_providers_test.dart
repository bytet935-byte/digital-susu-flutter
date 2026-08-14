import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/dashboard/data/mock_dashboard_repository.dart';
import 'package:digital_susu/features/dashboard/presentation/providers/dashboard_providers.dart';

void main() {
  test('dashboard summary provider loads mock data (spec §13)', () async {
    final container = ProviderContainer(
      overrides: <Override>[
        dashboardRepositoryProvider.overrideWithValue(
          MockDashboardRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final summary = await container.read(dashboardSummaryProvider.future);

    expect(summary.totalBalance.amountMinor, 125000);
    expect(summary.activeGroups, isNotEmpty);
    expect(summary.recentTransactions, isNotEmpty);
    expect(summary.unreadNotifications, 3);
  });
}
