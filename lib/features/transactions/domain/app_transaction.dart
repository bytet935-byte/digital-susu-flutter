import 'package:equatable/equatable.dart';

import '../../../shared/models/money.dart';

/// Financial transaction (spec §8, §14).
class AppTransaction extends Equatable {
  const AppTransaction({
    required this.id,
    required this.type,
    required this.description,
    required this.amount,
    required this.timestamp,
    this.status = 'SUCCESSFUL',
    this.reference,
    this.groupName,
    this.paymentMethod,
  });

  final String id;

  /// CONTRIBUTION / DEPOSIT / WITHDRAWAL / PAYOUT / FEE / PENALTY / ...
  final String type;
  final String description;

  /// Negative = debit, positive = credit.
  final Money amount;
  final DateTime timestamp;

  /// SUCCESSFUL / PENDING / FAILED / REVERSED (spec §14).
  final String status;

  /// External payment reference (kept separate from internal ids, spec §9).
  final String? reference;
  final String? groupName;
  final String? paymentMethod;

  bool get isCredit => amount.amountMinor >= 0;

  factory AppTransaction.fromJson(Map<String, dynamic> json) =>
      AppTransaction(
        id: json['id'] as String,
        type: json['type'] as String? ?? 'TRANSACTION',
        description: json['description'] as String? ?? '',
        amount: Money.fromMajor((json['amount'] as num?)?.toDouble() ?? 0),
        timestamp: DateTime.tryParse(json['timestamp'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
        status: json['status'] as String? ?? 'SUCCESSFUL',
        reference: json['reference'] as String?,
        groupName: json['group_name'] as String?,
        paymentMethod: json['payment_method'] as String?,
      );

  @override
  List<Object?> get props => <Object?>[
        id,
        type,
        description,
        amount,
        timestamp,
        status,
        reference,
        groupName,
        paymentMethod,
      ];
}
