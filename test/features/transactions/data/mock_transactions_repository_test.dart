import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/transactions/data/mock_transactions_repository.dart';

void main() {
  group('MockTransactionsRepository (spec §14)', () {
    test('returns design-reference transactions with mixed statuses', () async {
      final items =
          (await MockTransactionsRepository().getTransactions()).valueOrNull!;
      expect(items, hasLength(5));
      expect(items.first.type, 'CONTRIBUTION');
      expect(items.first.isCredit, isFalse);
    });

    test('credits are positive, debits negative (clear financial formatting)',
        () async {
      final items =
          (await MockTransactionsRepository().getTransactions()).valueOrNull!;
      final topUp = items.firstWhere((t) => t.type == 'DEPOSIT');
      final payout = items.firstWhere((t) => t.type == 'PAYOUT');
      expect(topUp.isCredit, isTrue);
      expect(topUp.amount.amountMinor, greaterThan(0));
      expect(payout.isCredit, isTrue);
      expect(items.where((t) => t.type == 'CONTRIBUTION').every((t) => !t.isCredit),
          isTrue);
    });

    test('carries reference, group and payment-method information', () async {
      final items =
          (await MockTransactionsRepository().getTransactions()).valueOrNull!;
      final contribution = items.first;
      expect(contribution.reference, 'TXN-20260817-0001');
      expect(contribution.groupName, 'Weekend Susu');
      expect(contribution.paymentMethod, 'Mobile Money');
    });

    test('includes pending and successful statuses', () async {
      final items =
          (await MockTransactionsRepository().getTransactions()).valueOrNull!;
      expect(items.any((t) => t.status == 'PENDING'), isTrue);
      expect(items.any((t) => t.status == 'SUCCESSFUL'), isTrue);
    });
  });
}
