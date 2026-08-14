import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/result.dart';
import '../domain/dashboard_models.dart';
import '../domain/dashboard_repository.dart';

/// Real-backend dashboard repository — the server returns a
/// permission-filtered summary (spec §13).
class ApiDashboardRepository implements DashboardRepository {
  ApiDashboardRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<DashboardSummary>> getSummary() async {
    try {
      final data = await _client.getMap(ApiEndpoints.dashboard);
      return Success<DashboardSummary>(DashboardSummary.fromJson(data));
    } on AppException catch (error) {
      return Failure<DashboardSummary>(error);
    }
  }
}
