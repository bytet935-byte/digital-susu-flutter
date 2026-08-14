import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/config/app_config.dart';
import 'package:digital_susu/core/config/environment.dart';

void main() {
  group('AppConfig — Ghana-first defaults (spec §2)', () {
    test('country is Ghana', () {
      expect(AppConfig.countryCode, 'GH');
      expect(AppConfig.countryName, 'Ghana');
    });

    test('currency is GHS with GH₵ symbol and 100 minor units', () {
      expect(AppConfig.currencyCode, 'GHS');
      expect(AppConfig.currencySymbol, 'GH₵');
      expect(AppConfig.currencyMinorUnit, 100);
    });

    test('phone country code is +233', () {
      expect(AppConfig.phoneCountryCode, '+233');
      expect(AppConfig.phoneCountryCodeDigits, '233');
    });

    test('timezone and locale are Ghana', () {
      expect(AppConfig.timezone, 'Africa/Accra');
      expect(AppConfig.locale, 'en-GH');
    });

    test('OTP length is 6 (spec §10)', () {
      expect(AppConfig.otpLength, 6);
    });

    test('payment methods include mobile money, bank transfer and card', () {
      expect(AppConfig.supportedPaymentMethods,
          containsAll(<String>['mobile_money', 'bank_transfer', 'card']));
    });
  });

  group('AppEnvironment defaults', () {
    test('mock data is enabled by default (dev-friendly)', () {
      expect(AppEnvironment.useMockData, isTrue);
    });

    test('API base URL has a sane default', () {
      expect(AppEnvironment.apiBaseUrl, isNotEmpty);
      expect(AppEnvironment.apiBaseUrl, startsWith('https://'));
    });
  });
}
