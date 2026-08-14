import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/api_dashboard_repository.dart';
import '../../data/mock_dashboard_repository.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';

/// Switches mock/API via USE_MOCK_DATA (spec §11).
final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return selectRepository<DashboardRepository>(
    mock: MockDashboardRepository(),
    api: ApiDashboardRepository(ref.watch(apiClientProvider)),
  );
});

/// Loads the permission-filtered dashboard summary; exposes refresh().
final dashboardSummaryProvider =
    AsyncNotifierProvider<DashboardSummaryController, DashboardSummary>(
  DashboardSummaryController.new,
);

class DashboardSummaryController
    extends AsyncNotifier<DashboardSummary> {
  @override
  Future<DashboardSummary> build() => _fetch();

  Future<DashboardSummary> _fetch() async {
    final result = await ref.read(dashboardRepositoryProvider).getSummary();
    return switch (result) {
      Success<DashboardSummary>(:final value) => value,
      Failure<DashboardSummary>(:final error) => throw error,
    };
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
