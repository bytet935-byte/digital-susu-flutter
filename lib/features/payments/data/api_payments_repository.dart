import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/money.dart';
import '../domain/payment_models.dart';
import '../domain/payments_repository.dart';

/// Payments ledger backed by the transactions endpoint
/// (`GET /transactions`) — the server has no dedicated payments route.
class ApiPaymentsRepository implements PaymentsRepository {
  ApiPaymentsRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<List<Payment>>> getPayments() async {
    try {
      final data = await _client.getList(ApiEndpoints.transactions);
      final payments = data.whereType<Map<String, dynamic>>().map(_map).toList();
      return Success<List<Payment>>(payments);
    } on AppException catch (error) {
      return Failure<List<Payment>>(error);
    }
  }

  Payment _map(Map<String, dynamic> json) {
    final createdAt = json['created_at'];
    return Payment(
      id: json['id'] as String,
      type: json['type'] as String? ?? 'OTHER',
      description: json['description'] as String? ?? '',
      amount: Money((json['amount_minor'] as num?)?.toInt() ?? 0),
      timestamp: createdAt is String
          ? DateTime.tryParse(createdAt) ?? DateTime.now()
          : DateTime.now(),
      status: json['status'] as String? ?? PaymentStatuses.completed,
    );
  }
}
