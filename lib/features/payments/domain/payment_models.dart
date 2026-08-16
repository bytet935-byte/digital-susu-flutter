import 'package:equatable/equatable.dart';

import '../../../shared/models/money.dart';

/// Payment statuses (design reference screen 10).
abstract final class PaymentStatuses {
  static const String completed = 'COMPLETED';
  static const String pending = 'PENDING';
  static const String failed = 'FAILED';
}

/// A payment / ledger entry (design reference screen 10): wallet balance on
/// top, payments below with timestamps, amounts color-coded (green credits /
/// red debits) and status chips.
class Payment extends Equatable {
  const Payment({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.timestamp,
    this.status = PaymentStatuses.completed,
  });

  final String id;

  /// `CONTRIBUTION` | `TOP_UP` | `WITHDRAWAL` | `SEND` | `AIRTIME` | …
  final String type;
  final String description;

  /// Negative for debits (contributions, withdrawals, sends).
  final Money amount;
  final DateTime timestamp;
  final String status;

  bool get isCredit => amount.amountMinor >= 0;

  @override
  List<Object?> get props =>
      <Object?>[id, type, description, amount, timestamp, status];
}
