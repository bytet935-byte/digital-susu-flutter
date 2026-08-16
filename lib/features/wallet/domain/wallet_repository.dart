import '../../../core/utils/result.dart';
import '../../../shared/models/money.dart';
import 'wallet_models.dart';

/// Personal wallet operations (spec §7).
abstract interface class WalletRepository {
  Future<Result<WalletSummary>> getSummary();

  Future<Result<WalletSummary>> topUp(Money amount);

  Future<Result<WalletSummary>> withdraw(Money amount);
}
