// prefer_const_constructors fires here even though DateTime(...) cannot be
// const — the lint does not deep-check constructor arguments.
// ignore_for_file: prefer_const_constructors

import '../../../core/utils/result.dart';
import '../../../shared/models/money.dart';
import '../domain/payment_models.dart';
import '../domain/payments_repository.dart';

/// Deterministic mock payments ledger (design reference screen 10): eight
/// payments newest first, one pending, one failed, mixed credits/debits.
class MockPaymentsRepository implements PaymentsRepository {
  static final List<Payment> _payments = <Payment>[
    Payment(
      id: 'pay_1',
      type: 'CONTRIBUTION',
      description: 'Weekend Susu contribution',
      amount: Money(-5000),
      timestamp: DateTime(2026, 8, 14, 9, 30),
    ),
    Payment(
      id: 'pay_2',
      type: 'TOP_UP',
      description: 'Wallet top-up',
      amount: Money(20000),
      timestamp: DateTime(2026, 8, 13, 18, 5),
    ),
    Payment(
      id: 'pay_3',
      type: 'WITHDRAWAL',
      description: 'Wallet withdrawal',
      amount: Money(-30000),
      timestamp: DateTime(2026, 8, 12, 12, 45),
    ),
    Payment(
      id: 'pay_4',
      type: 'CONTRIBUTION',
      description: 'Project Susu contribution',
      amount: Money(-5000),
      timestamp: DateTime(2026, 8, 11, 8, 20),
    ),
    Payment(
      id: 'pay_5',
      type: 'AIRTIME',
      description: 'Airtime purchase',
      amount: Money(-1000),
      timestamp: DateTime(2026, 8, 10, 15, 10),
    ),
    Payment(
      id: 'pay_6',
      type: 'SEND',
      description: 'Sent to Ama Serwaa',
      amount: Money(-2500),
      timestamp: DateTime(2026, 8, 9, 11, 0),
    ),
    Payment(
      id: 'pay_7',
      type: 'CONTRIBUTION',
      description: 'Business Susu contribution',
      amount: Money(-10000),
      timestamp: DateTime(2026, 8, 7, 16, 40),
      status: PaymentStatuses.pending,
    ),
    Payment(
      id: 'pay_8',
      type: 'TOP_UP',
      description: 'Card top-up',
      amount: Money(10000),
      timestamp: DateTime(2026, 8, 5, 10, 5),
      status: PaymentStatuses.failed,
    ),
  ];

  @override
  Future<Result<List<Payment>>> getPayments() async =>
      Success<List<Payment>>(_payments);
}
