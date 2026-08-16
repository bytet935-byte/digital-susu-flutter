import '../../../core/utils/result.dart';
import 'payment_models.dart';

/// Payments ledger (design reference screen 10; spec §14 reconciliation).
abstract interface class PaymentsRepository {
  Future<Result<List<Payment>>> getPayments();
}
