/// Input validators returning a user-friendly error message, or `null` when
/// the value is valid (spec §27 — input validation, friendly errors §12).
abstract final class Validators {
  static final RegExp _ghanaPhone =
      RegExp(r'^(\+?233|0)[2357]\d{8}$');
  static final RegExp _email = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );
  static final RegExp _digits = RegExp(r'^\d+$');

  /// Ghanaian mobile number (e.g. `0241234567`, `+233241234567`).
  static String? phone(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter your phone number';
    final digits = trimmed.replaceAll(RegExp(r'[\s\-()]'), '');
    if (!_ghanaPhone.hasMatch(digits)) {
      return 'Enter a valid Ghanaian phone number';
    }
    return null;
  }

  static String? email(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return null; // email is optional in Ghana-first flow
    if (!_email.hasMatch(trimmed)) return 'Enter a valid email address';
    return null;
  }

  /// 6-digit OTP (spec §10).
  static String? otp(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the 6-digit code';
    if (trimmed.length != 6 || !_digits.hasMatch(trimmed)) {
      return 'The code must be exactly 6 digits';
    }
    return null;
  }

  /// Positive monetary amount with at most 2 decimal places.
  static String? amount(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter an amount';
    final parsed = double.tryParse(trimmed);
    if (parsed == null || !parsed.isFinite) return 'Enter a valid amount';
    if (parsed <= 0) return 'Amount must be greater than zero';
    if (trimmed.contains('.') && trimmed.split('.')[1].length > 2) {
      return 'Amount can have at most 2 decimal places';
    }
    return null;
  }

  /// Person/group display name.
  static String? name(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter a name';
    if (trimmed.length < 2) return 'Name is too short';
    if (trimmed.length > 60) return 'Name is too long';
    return null;
  }

  /// Generic non-empty required field.
  static String? required(String? value, {String message = 'This field is required'}) {
    return (value == null || value.trim().isEmpty) ? message : null;
  }
}
