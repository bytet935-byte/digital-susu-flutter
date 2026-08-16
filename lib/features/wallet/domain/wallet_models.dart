import 'package:equatable/equatable.dart';

import '../../../shared/models/money.dart';

/// Personal wallet summary (spec §7): available balance plus recent wallet
/// activity. Group wallets stay strictly separate.
class WalletSummary extends Equatable {
  const WalletSummary({
    required this.balance,
    required this.recentTransactions,
  });

  final Money balance;
  final List<WalletTransaction> recentTransactions;

  @override
  List<Object?> get props => <Object?>[balance, recentTransactions];
}

/// A personal-wallet transaction: top-up, withdrawal, send, airtime, …
class WalletTransaction extends Equatable {
  const WalletTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.timestamp,
  });

  final String id;

  /// `TOP_UP`, `WITHDRAWAL`, `SEND`, `AIRTIME`, `CONTRIBUTION`, …
  final String type;
  final String description;

  /// Negative for debits (withdrawals, sends, contributions).
  final Money amount;
  final DateTime timestamp;

  bool get isCredit => amount.amountMinor >= 0;

  @override
  List<Object?> get props => <Object?>[id, type, description, amount, timestamp];
}
