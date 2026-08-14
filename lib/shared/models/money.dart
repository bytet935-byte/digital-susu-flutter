import 'package:equatable/equatable.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/formatters.dart';

/// Value type for monetary amounts — financial integrity foundation (spec §8).
///
/// Amounts are stored as **integer minor units** (pesewas) to eliminate
/// floating-point drift in financial arithmetic. All comparisons and
/// arithmetic happen on integers.
///
/// Two amounts can only be combined when their currencies match; mismatches
/// throw [ArgumentError] instead of silently mixing currencies (spec §7).
class Money extends Equatable {
  const Money(this.amountMinor, {this.currency = AppConfig.currencyCode});

  /// Creates money from a major-unit value, rounding to the nearest minor unit
  /// (e.g. `Money.fromMajor(10.005)` → 1000 pesewas in GHS context — GHS
  /// minor unit is 0.01, so 10.005 is not representable; use explicit minor
  /// units for exact values).
  factory Money.fromMajor(num amount,
      {String currency = AppConfig.currencyCode}) {
    final minor = (amount * AppConfig.currencyMinorUnit).round();
    return Money(minor, currency: currency);
  }

  factory Money.zero({String currency = AppConfig.currencyCode}) =>
      Money(0, currency: currency);

  /// Amount in minor units (pesewas for GHS).
  final int amountMinor;

  /// ISO 4217 currency code.
  final String currency;

  /// Symbol used for display; defaults to the app-configured symbol.
  String? get currencySymbol => currency == AppConfig.currencyCode
      ? AppConfig.currencySymbol
      : null;

  /// Major-unit value (e.g. 12.5 for 1250 pesewas). Display only — never
  /// used for arithmetic.
  double get amountMajor => amountMinor / AppConfig.currencyMinorUnit;

  bool get isZero => amountMinor == 0;
  bool get isNegative => amountMinor < 0;

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor + other.amountMinor, currency: currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money(amountMinor - other.amountMinor, currency: currency);
  }

  Money operator *(num factor) =>
      Money((amountMinor * factor).round(), currency: currency);

  Money operator -() => Money(-amountMinor, currency: currency);

  bool operator >(Money other) {
    _assertSameCurrency(other);
    return amountMinor > other.amountMinor;
  }

  bool operator >=(Money other) {
    _assertSameCurrency(other);
    return amountMinor >= other.amountMinor;
  }

  bool operator <(Money other) {
    _assertSameCurrency(other);
    return amountMinor < other.amountMinor;
  }

  bool operator <=(Money other) {
    _assertSameCurrency(other);
    return amountMinor <= other.amountMinor;
  }

  /// Absolute value (minor units preserved).
  Money abs() => Money(amountMinor.abs(), currency: currency);

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw ArgumentError(
        'Cannot combine currencies: $currency and ${other.currency}',
      );
    }
  }

  /// Display form via [CurrencyFormatter] — e.g. `GH₵ 1,234.50`.
  String format() => CurrencyFormatter.formatMoney(this);

  @override
  List<Object?> get props => <Object?>[amountMinor, currency];

  @override
  String toString() => format();
}
