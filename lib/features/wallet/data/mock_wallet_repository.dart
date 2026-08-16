import '../../../core/errors/app_exception.dart';
import '../../../core/utils/result.dart';
import '../../../shared/models/money.dart';
import '../domain/wallet_models.dart';
import '../domain/wallet_repository.dart';

/// Deterministic mock wallet matching the design reference (spec §7, §11):
/// GHS 1,250.00 balance, six wallet transactions (green credits / red
/// debits), and top-up / withdraw that mutate the in-memory state.
class MockWalletRepository implements WalletRepository {
  Money _balance = const Money(125000);

  final List<WalletTransaction> _transactions = <WalletTransaction>[
    WalletTransaction(
      id: 'txn_w1',
      type: 'CONTRIBUTION',
      description: 'Weekend Susu contribution',
      amount: const Money(-5000),
      timestamp: DateTime(2026, 8, 14, 9, 30),
    ),
    WalletTransaction(
      id: 'txn_w2',
      type: 'TOP_UP',
      description: 'Wallet top-up',
      amount: const Money(20000),
      timestamp: DateTime(2026, 8, 13, 18, 5),
    ),
    WalletTransaction(
      id: 'txn_w3',
      type: 'WITHDRAWAL',
      description: 'Wallet withdrawal',
      amount: const Money(-30000),
      timestamp: DateTime(2026, 8, 12, 12, 45),
    ),
    WalletTransaction(
      id: 'txn_w4',
      type: 'CONTRIBUTION',
      description: 'Project Susu contribution',
      amount: const Money(-5000),
      timestamp: DateTime(2026, 8, 11, 8, 20),
    ),
    WalletTransaction(
      id: 'txn_w5',
      type: 'AIRTIME',
      description: 'Airtime purchase',
      amount: const Money(-1000),
      timestamp: DateTime(2026, 8, 10, 15, 10),
    ),
    WalletTransaction(
      id: 'txn_w6',
      type: 'SEND',
      description: 'Sent to Ama Serwaa',
      amount: const Money(-2500),
      timestamp: DateTime(2026, 8, 9, 11, 0),
    ),
  ];

  @override
  Future<Result<WalletSummary>> getSummary() async =>
      Success<WalletSummary>(_snapshot());

  @override
  Future<Result<WalletSummary>> topUp(Money amount) async {
    if (amount.amountMinor <= 0) {
      return const Failure<WalletSummary>(
        ValidationException(message: 'Enter an amount greater than zero.'),
      );
    }
    _balance += amount;
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'txn_w_${DateTime.now().millisecondsSinceEpoch}',
        type: 'TOP_UP',
        description: 'Wallet top-up',
        amount: amount,
        timestamp: DateTime.now(),
      ),
    );
    return Success<WalletSummary>(_snapshot());
  }

  @override
  Future<Result<WalletSummary>> withdraw(Money amount) async {
    if (amount.amountMinor <= 0) {
      return const Failure<WalletSummary>(
        ValidationException(message: 'Enter an amount greater than zero.'),
      );
    }
    if (amount > _balance) {
      return const Failure<WalletSummary>(
        ValidationException(message: 'Insufficient balance for this withdrawal.'),
      );
    }
    _balance -= amount;
    _transactions.insert(
      0,
      WalletTransaction(
        id: 'txn_w_${DateTime.now().millisecondsSinceEpoch}',
        type: 'WITHDRAWAL',
        description: 'Wallet withdrawal',
        amount: -amount,
        timestamp: DateTime.now(),
      ),
    );
    return Success<WalletSummary>(_snapshot());
  }

  WalletSummary _snapshot() => WalletSummary(
        balance: _balance,
        recentTransactions: List<WalletTransaction>.of(_transactions),
      );
}
