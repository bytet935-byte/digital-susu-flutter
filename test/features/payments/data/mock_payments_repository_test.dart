import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/payments/data/mock_payments_repository.dart';
import 'package:digital_susu/features/payments/domain/payment_models.dart';

void main() {
  group('MockPaymentsRepository', () {
    test('returns the design-reference ledger newest first', () async {
      final repo = MockPaymentsRepository();
      final result = await repo.getPayments();

      expect(result.isSuccess, isTrue);
      final payments = result.valueOrNull!;
      expect(payments, hasLength(8));
      expect(payments.first.description, 'Weekend Susu contribution');
      expect(
        payments[1].timestamp.isAfter(payments[2].timestamp),
        isTrue,
      );
    });

    test('includes credits, debits and mixed statuses', () async {
      final repo = MockPaymentsRepository();
      final payments = (await repo.getPayments()).valueOrNull!;

      expect(payments.any((p) => p.isCredit), isTrue);
      expect(payments.any((p) => !p.isCredit), isTrue);

      expect(
        payments.any((p) => p.status == PaymentStatuses.pending),
        isTrue,
      );
      expect(
        payments.any((p) => p.status == PaymentStatuses.failed),
        isTrue,
      );
      expect(
        payments.every(
          (p) =>
              p.status == PaymentStatuses.completed ||
              p.status == PaymentStatuses.pending ||
              p.status == PaymentStatuses.failed,
        ),
        isTrue,
      );
    });
  });
}
