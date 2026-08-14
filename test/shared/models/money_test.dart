import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/shared/models/money.dart';

void main() {
  group('Money — integer minor-unit arithmetic (spec §8)', () {
    test('fromMajor converts with rounding', () {
      expect(Money.fromMajor(10.5).amountMinor, 1050);
      expect(Money.fromMajor(0.01).amountMinor, 1);
      expect(Money.fromMajor(0).amountMinor, 0);
    });

    test('addition and subtraction are exact (no float drift)', () {
      const a = Money(1050); // 10.50
      const b = Money(150); // 1.50
      expect((a + b).amountMinor, 1200);
      expect((a - b).amountMinor, 900);
      // 0.1 + 0.2 as floats is 0.30000000000000004; minor units are exact.
      expect((Money.fromMajor(0.1) + Money.fromMajor(0.2)).amountMinor, 30);
    });

    test('multiplication and negation', () {
      expect((const Money(100) * 3).amountMinor, 300);
      expect((-const Money(100)).amountMinor, -100);
      expect(const Money(100).abs().amountMinor, 100);
      expect(const Money(-100).abs().amountMinor, 100);
    });

    test('comparison operators', () {
      expect(const Money(100) > const Money(50), isTrue);
      expect(const Money(100) >= const Money(100), isTrue);
      expect(const Money(50) < const Money(100), isTrue);
      expect(const Money(50) <= const Money(50), isTrue);
    });

    test('zero and sign helpers', () {
      expect(Money.zero().isZero, isTrue);
      expect(const Money(-5).isNegative, isTrue);
      expect(const Money(5).isNegative, isFalse);
    });

    test('mixing currencies throws instead of silently combining (spec §7)', () {
      const ghs = Money(100);
      const usd = Money(100, currency: 'USD');
      expect(() => ghs + usd, throwsArgumentError);
      expect(() => ghs > usd, throwsArgumentError);
    });

    test('equality compares amount and currency', () {
      expect(const Money(100), const Money(100));
      expect(const Money(100, currency: 'USD'), isNot(const Money(100)));
    });

    test('format delegates to CurrencyFormatter', () {
      expect(const Money(123450).format(), 'GH₵ 1,234.50');
    });
  });
}
