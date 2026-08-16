import '../../../../core/errors/app_exception.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../core/utils/result.dart';
import '../../../../shared/models/money.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_repository.dart';

/// Live wallet backed by the Digital Susu API (spec §7, §12):
/// `GET /wallet` (balance) + `GET /transactions` (activity),
/// `POST /wallet/top-up` and `POST /wallet/withdraw`.
class ApiWalletRepository implements WalletRepository {
  ApiWalletRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<WalletSummary>> getSummary() async {
    try {
      final wallet = await _client.getMap(ApiEndpoints.wallet);
      final transactions =
          await _client.getList(ApiEndpoints.transactions);
      return Success<WalletSummary>(_parse(wallet, transactions));
    } on AppException catch (error) {
      return Failure<WalletSummary>(error);
    }
  }

  @override
  Future<Result<WalletSummary>> topUp(Money amount) async {
    try {
      final wallet = await _client.postMap(
        ApiEndpoints.walletTopUp,
        data: <String, dynamic>{'amount_minor': amount.amountMinor},
      );
      final transactions = await _client.getList(ApiEndpoints.transactions);
      return Success<WalletSummary>(_parse(wallet, transactions));
    } on AppException catch (error) {
      return Failure<WalletSummary>(error);
    }
  }

  @override
  Future<Result<WalletSummary>> withdraw(Money amount) async {
    try {
      final wallet = await _client.postMap(
        ApiEndpoints.walletWithdraw,
        data: <String, dynamic>{'amount_minor': amount.amountMinor},
      );
      final transactions = await _client.getList(ApiEndpoints.transactions);
      return Success<WalletSummary>(_parse(wallet, transactions));
    } on AppException catch (error) {
      return Failure<WalletSummary>(error);
    }
  }

  WalletSummary _parse(
    Map<String, dynamic> walletData,
    List<dynamic> transactionsData,
  ) {
    final wallet = walletData['wallet'];
    if (wallet is! Map<String, dynamic>) {
      throw const MalformedResponseException();
    }
    final balanceMinor = wallet['balance'];
    if (balanceMinor is! int) {
      throw const MalformedResponseException();
    }
    final transactions = <WalletTransaction>[];
    for (final item in transactionsData) {
      if (item is! Map<String, dynamic>) continue;
      final id = item['id'];
      final amountMinor = item['amount_minor'];
      final description = item['description'];
      if (id is! String || amountMinor is! int || description is! String) {
        continue;
      }
      final createdAt = item['created_at'];
      transactions.add(
        WalletTransaction(
          id: id,
          type: item['type'] is String ? item['type'] as String : 'OTHER',
          description: description,
          amount: Money(amountMinor),
          timestamp: createdAt is String
              ? DateTime.tryParse(createdAt) ?? DateTime.now()
              : DateTime.now(),
        ),
      );
    }
    return WalletSummary(
      balance: Money(balanceMinor),
      recentTransactions: transactions,
    );
  }
}
