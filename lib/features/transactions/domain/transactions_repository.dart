import '../../../../core/utils/result.dart';
import 'app_transaction.dart';

/// Transaction history contract (spec §14).
abstract interface class TransactionsRepository {
  Future<Result<List<AppTransaction>>> getTransactions();
}
