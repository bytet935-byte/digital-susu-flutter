import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../domain/app_transaction.dart';
import '../domain/transactions_repository.dart';

/// Real-backend transaction history (spec §14).
class ApiTransactionsRepository implements TransactionsRepository {
  ApiTransactionsRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<List<AppTransaction>>> getTransactions() async {
    try {
      final data = await _client.getList(ApiEndpoints.transactions);
      return Success<List<AppTransaction>>(data
          .whereType<Map<String, dynamic>>()
          .map(AppTransaction.fromJson)
          .toList());
    } on AppException catch (error) {
      return Failure<List<AppTransaction>>(error);
    }
  }
}
