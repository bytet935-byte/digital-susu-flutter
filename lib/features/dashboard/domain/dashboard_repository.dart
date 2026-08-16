import '../../../core/utils/result.dart';
import 'dashboard_models.dart';

/// Dashboard data contract (spec §13). Implementations: mock (demo) and API
/// (permission-filtered server payload).
abstract interface class DashboardRepository {
  Future<Result<DashboardSummary>> getSummary();
}
