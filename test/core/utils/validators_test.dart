import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/utils/validators.dart';

void main() {
  group('Validators.phone', () {
    test('accepts valid Ghanaian numbers', () {
      expect(Validators.phone('0241234567'), isNull);
      expect(Validators.phone('+233241234567'), isNull);
      expect(Validators.phone('024 123 4567'), isNull);
      expect(Validators.phone('0551234567'), isNull); // MTN 055 prefix
    });

    test('rejects invalid numbers', () {
      expect(Validators.phone(''), isNotNull);
      expect(Validators.phone('12345'), isNotNull);
      expect(Validators.phone('0191234567'), isNotNull); // unsupported prefix
      expect(Validators.phone('024123456'), isNotNull); // too short
    });
  });

  group('Validators.otp', () {
    test('accepts exactly 6 digits', () {
      expect(Validators.otp('123456'), isNull);
    });

    test('rejects wrong length and non-digits', () {
      expect(Validators.otp('12345'), isNotNull);
      expect(Validators.otp('1234567'), isNotNull);
      expect(Validators.otp('12ab56'), isNotNull);
      expect(Validators.otp(''), isNotNull);
    });
  });

  group('Validators.amount', () {
    test('accepts positive amounts with up to 2 decimals', () {
      expect(Validators.amount('10'), isNull);
      expect(Validators.amount('10.5'), isNull);
      expect(Validators.amount('0.01'), isNull);
    });

    test('rejects zero, negatives, junk and >2 decimals', () {
      expect(Validators.amount('0'), isNotNull);
      expect(Validators.amount('-5'), isNotNull);
      expect(Validators.amount('10.999'), isNotNull);
      expect(Validators.amount('abc'), isNotNull);
      expect(Validators.amount(''), isNotNull);
    });
  });

  group('Validators.email', () {
    test('email is optional but validated when present', () {
      expect(Validators.email(''), isNull);
      expect(Validators.email('user@example.com'), isNull);
      expect(Validators.email('not-an-email'), isNotNull);
    });
  });

  group('Validators.name', () {
    test('validates name length', () {
      expect(Validators.name('Kojo'), isNull);
      expect(Validators.name('A'), isNotNull);
      expect(Validators.name(''), isNotNull);
    });
  });
}
