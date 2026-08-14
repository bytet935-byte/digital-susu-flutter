import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/utils/formatters.dart';
import 'package:digital_susu/shared/models/money.dart';

void main() {
  group('CurrencyFormatter', () {
    test('formats minor units to major display with symbol', () {
      expect(CurrencyFormatter.formatMoney(const Money(123450)), 'GH₵ 1,234.50');
    });

    test('formats zero', () {
      expect(CurrencyFormatter.formatMoney(Money.zero()), 'GH₵ 0.00');
    });

    test('compact format for thousands and millions', () {
      expect(CurrencyFormatter.formatMoneyCompact(const Money(1500000)),
          'GH₵ 1.5M');
      expect(CurrencyFormatter.formatMoneyCompact(const Money(250000)),
          'GH₵ 250K');
      expect(CurrencyFormatter.formatMoneyCompact(const Money(999)),
          'GH₵ 9.99');
    });

    test('formatAmount wraps a raw number', () {
      expect(CurrencyFormatter.formatAmount(42.5), 'GH₵ 42.50');
    });
  });

  group('PhoneFormatter', () {
    test('normalizes separators and plus', () {
      expect(PhoneFormatter.normalize('+233 24 123 4567'), '233241234567');
    });

    test('toE164 from local 0-prefixed number', () {
      expect(PhoneFormatter.toE164('0241234567'), '+233241234567');
    });

    test('toE164 from already-international number', () {
      expect(PhoneFormatter.toE164('233241234567'), '+233241234567');
      expect(PhoneFormatter.toE164('+233241234567'), '+233241234567');
    });

    test('formatDisplay groups digits', () {
      expect(PhoneFormatter.formatDisplay('0241234567'), '+233 24 123 4567');
    });
  });

  group('DateFormatter', () {
    test('formats a date', () {
      expect(DateFormatter.formatDate(DateTime(2026, 8, 14)), '14 Aug 2026');
    });
  });
}
