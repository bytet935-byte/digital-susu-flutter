import 'package:intl/intl.dart';

import '../config/app_config.dart';
import '../../shared/models/money.dart';

/// Formatting helpers for Ghana-first display (spec §2).
///
/// All money display flows through [CurrencyFormatter] so currency/symbol
/// changes (future markets) are applied in one place.
abstract final class CurrencyFormatter {
  /// Formats [Money] as e.g. `GH₵ 1,234.50`.
  ///
  /// Uses an explicit pattern with the configured symbol rather than a locale
  /// that may be missing from `intl` data (e.g. `en_GH`), keeping output
  /// deterministic across devices.
  static String formatMoney(Money money) {
    final number = NumberFormat('#,##0.00').format(money.amountMajor);
    final symbol = money.currencySymbol ?? AppConfig.currencySymbol;
    return '$symbol $number';
  }

  /// Compact form for dense UI: `GH₵ 1.2K`, `GH₵ 3.4M`.
  static String formatMoneyCompact(Money money) {
    final major = money.amountMajor;
    final symbol = money.currencySymbol ?? AppConfig.currencySymbol;
    if (major >= 1000000) {
      return '$symbol ${_trimZeros(major / 1000000)}M';
    }
    if (major >= 1000) {
      return '$symbol ${_trimZeros(major / 1000)}K';
    }
    return formatMoney(money);
  }

  /// Formats a plain number with the app currency symbol (non-Money contexts).
  static String formatAmount(num amount) =>
      formatMoney(Money.fromMajor(amount));

  static String _trimZeros(double value) {
    final text = value.toStringAsFixed(1);
    return text.endsWith('.0') ? text.substring(0, text.length - 2) : text;
  }
}

/// Ghanaian phone number helpers.
abstract final class PhoneFormatter {
  /// Removes spaces, dashes, parentheses and leading `+` for comparison.
  static String normalize(String input) {
    var digits = input.replaceAll(RegExp(r'[\s\-()]'), '');
    if (digits.startsWith('+')) digits = digits.substring(1);
    return digits;
  }

  /// Converts a local Ghanaian number to E.164 (`+233XXXXXXXXX`).
  ///
  /// Accepts `0241234567`, `233241234567`, `+233241234567`.
  static String toE164(String input) {
    final digits = normalize(input);
    if (digits.startsWith(AppConfig.phoneCountryCodeDigits)) {
      return '+$digits';
    }
    if (digits.startsWith('0')) {
      return '+${AppConfig.phoneCountryCodeDigits}${digits.substring(1)}';
    }
    return '+$digits';
  }

  /// Formats for display: `+233 24 123 4567`.
  static String formatDisplay(String input) {
    final e164 = toE164(input);
    if (e164.length != 13) return input;
    return '+${e164.substring(1, 4)} ${e164.substring(4, 6)} '
        '${e164.substring(6, 9)} ${e164.substring(9)}';
  }
}

/// Date/time formatting. Uses a stable locale (`en`) for the numeric/long
/// forms to avoid locale-data availability issues; `en-GH` remains the
/// configured app locale for Material widgets.
abstract final class DateFormatter {
  static final DateFormat _date = DateFormat('d MMM yyyy');
  static final DateFormat _dateTime = DateFormat('d MMM yyyy, h:mm a');
  static final DateFormat _time = DateFormat('h:mm a');

  static String formatDate(DateTime date) => _date.format(date.toLocal());

  static String formatDateTime(DateTime date) =>
      _dateTime.format(date.toLocal());

  static String formatTime(DateTime date) => _time.format(date.toLocal());
}
