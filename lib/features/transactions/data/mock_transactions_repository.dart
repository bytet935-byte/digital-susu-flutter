import '../../../../core/utils/result.dart';
import '../../../../shared/models/money.dart';
import '../domain/app_transaction.dart';
import '../domain/transactions_repository.dart';

/// Mock transaction history matching the design reference: contribution,
/// top-up (MTN Mobile Money), withdrawal (Bank Transfer), payout (spec §14).
class MockTransactionsRepository implements TransactionsRepository {
  static final List<AppTransaction> _items = <AppTransaction>[
    AppTransaction(
      id: 'txn_1',
      type: 'CONTRIBUTION',
      description: 'Weekend Susu contribution',
      amount: const Money(-5000),
      timestamp: DateTime(2026, 8, 17, 9, 30),
      reference: 'TXN-20260817-0001',
      groupName: 'Weekend Susu',
      paymentMethod: 'Mobile Money',
    ),
    AppTransaction(
      id: 'txn_2',
      type: 'DEPOSIT',
      description: 'Wallet top-up',
      amount: const Money(20000),
      timestamp: DateTime(2026, 8, 16, 18, 5),
      reference: 'TXN-20260816-0002',
      paymentMethod: 'MTN Mobile Money',
    ),
    AppTransaction(
      id: 'txn_3',
      type: 'WITHDRAWAL',
      description: 'Wallet withdrawal',
      amount: const Money(-30000),
      timestamp: DateTime(2026, 8, 15, 12, 45),
      reference: 'TXN-20260815-0003',
      paymentMethod: 'Bank Transfer',
    ),
    AppTransaction(
      id: 'txn_4',
      type: 'CONTRIBUTION',
      description: 'Project Susu contribution',
      amount: const Money(-10000),
      timestamp: DateTime(2026, 8, 14, 8, 20),
      status: 'PENDING',
      reference: 'TXN-20260814-0004',
      groupName: 'Project Susu',
      paymentMethod: 'Mobile Money',
    ),
    AppTransaction(
      id: 'txn_5',
      type: 'PAYOUT',
      description: 'Weekend Susu cycle 1 payout',
      amount: const Money(50000),
      timestamp: DateTime(2026, 7, 25, 16, 0),
      reference: 'TXN-20260725-0005',
      groupName: 'Weekend Susu',
      paymentMethod: 'Wallet Credit',
    ),
  ];

  @override
  Future<Result<List<AppTransaction>>> getTransactions() async =>
      Success<List<AppTransaction>>(_items);
}
