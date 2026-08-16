import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/wallet/data/mock_wallet_repository.dart';
import 'package:digital_susu/shared/models/money.dart';

void main() {
  group('MockWalletRepository', () {
    test('getSummary returns the design-reference wallet (GHS 1,250.00, newest first)', () async {
      final repo = MockWalletRepository();
      final result = await repo.getSummary();

      expect(result.isSuccess, isTrue);
      final summary = result.valueOrNull!;
      expect(summary.balance, const Money(125000));
      expect(summary.recentTransactions.first.description,
          'Weekend Susu contribution');
      expect(summary.recentTransactions.first.isCredit, isFalse);
      expect(
        summary.recentTransactions.any(
          (t) => t.type == 'TOP_UP' && t.isCredit,
        ),
        isTrue,
      );
    });

    test('topUp adds the amount and prepends a credit transaction', () async {
      final repo = MockWalletRepository();
      final before = (await repo.getSummary()).valueOrNull!;

      final result = await repo.topUp(const Money(20000));

      expect(result.isSuccess, isTrue);
      final after = result.valueOrNull!;
      expect(after.balance, before.balance + const Money(20000));
      expect(after.recentTransactions.first.type, 'TOP_UP');
      expect(after.recentTransactions.first.amount, const Money(20000));
      expect(after.recentTransactions.first.isCredit, isTrue);
    });

    test('withdraw deducts the amount and prepends a debit transaction', () async {
      final repo = MockWalletRepository();

      final result = await repo.withdraw(const Money(25000));

      expect(result.isSuccess, isTrue);
      final after = result.valueOrNull!;
      expect(after.balance, const Money(100000));
      expect(after.recentTransactions.first.type, 'WITHDRAWAL');
      expect(after.recentTransactions.first.isCredit, isFalse);
    });

    test('withdraw rejects amounts above the balance', () async {
      final repo = MockWalletRepository();

      final result = await repo.withdraw(const Money(99999999));

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ValidationException>());
    });

    test('topUp rejects zero and negative amounts', () async {
      final repo = MockWalletRepository();

      final result = await repo.topUp(const Money(0));

      expect(result.isFailure, isTrue);
      expect(result.errorOrNull, isA<ValidationException>());
    });
  });
}
