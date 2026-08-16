import '../../../../core/errors/app_exception.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

/// Deterministic in-memory auth backend for `USE_MOCK_DATA=true` (spec §11).
///
/// Demo account (matches the design reference profile):
/// - phone/email: `0241234567` (or `kwame@digitalsusu.example`)
/// - password: `123456`
/// - OTP: any 6 digits (e.g. `123456`)
class MockAuthRepository implements AuthRepository {
  final Map<String, String> _passwords = <String, String>{
    '0241234567': '123456',
    '233241234567': '123456',
    '+233241234567': '123456',
    'kwame@digitalsusu.example': '123456',
  };

  final Map<String, User> _users = <String, User>{
    '0241234567': User(
      id: 'usr_kwame',
      fullName: 'Kwame Owusu',
      phone: '+233241234567',
      email: 'kwame@digitalsusu.example',
      // VERIFIED so the home screen shows the blue "Verified" badge, exactly
      // like the React design reference.
      kycStatus: 'VERIFIED',
      createdAt: DateTime(2026, 1, 15),
    ),
  };

  /// Pending registrations awaiting OTP: identifier -> user draft.
  final Map<String, User> _pending = <String, User>{};

  User? _currentUser;
  String? _accessToken;

  User _demoUserFor(String identifier) {
    final normalized = _normalize(identifier);
    return _users[normalized] ??
        _users['0241234567']!; // unknown identifiers map to the demo user
  }

  String _normalize(String identifier) {
    var value = identifier.trim().toLowerCase();
    value = value.replaceAll(RegExp(r'[\s\-()]'), '');
    if (value.startsWith('+')) value = value.substring(1);
    return value;
  }

  bool _isEmail(String identifier) => identifier.contains('@');

  @override
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
  }) async {
    final key = _normalize(identifier);
    final expected = _passwords[key];
    if (expected == null) {
      return const Failure<AuthSession>(
        ValidationException(message: 'No account found for this phone number or email.'),
      );
    }
    if (password != expected) {
      return const Failure<AuthSession>(
        ValidationException(message: 'Incorrect password. Please try again.'),
      );
    }
    final user = _demoUserFor(identifier);
    _currentUser = user;
    _accessToken = 'mock_access_${DateTime.now().millisecondsSinceEpoch}';
    return Success<AuthSession>(_buildSession(user));
  }

  @override
  Future<Result<User>> register({
    required String fullName,
    required String identifier,
    required String password,
  }) async {
    if (fullName.trim().length < 2) {
      return const Failure<User>(
        ValidationException(message: 'Please enter your full name.'),
      );
    }
    if (password.length < 6) {
      return const Failure<User>(
        ValidationException(message: 'Password must be at least 6 characters.'),
      );
    }
    final phone = _isEmail(identifier) ? identifier : _normalize(identifier);
    final user = User(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      fullName: fullName.trim(),
      phone: phone,
      email: _isEmail(identifier) ? identifier.trim().toLowerCase() : null,
      kycStatus: 'NOT_STARTED',
      createdAt: DateTime.now(),
    );
    _pending[_normalize(identifier)] = user;
    _passwords[_normalize(identifier)] = password;
    return Success<User>(user);
  }

  @override
  Future<Result<AuthSession>> verifyOtp({
    required String phone,
    required String code,
  }) async {
    if (code.length != 6 || !RegExp(r'^\d{6}$').hasMatch(code)) {
      return const Failure<AuthSession>(
        ValidationException(message: 'Enter the 6-digit code sent to your phone.'),
      );
    }
    final key = _normalize(phone);
    final user = _pending[key] ?? _users[key] ?? _users['0241234567']!;
    _pending.remove(key);
    _currentUser = user;
    _accessToken = 'mock_access_${DateTime.now().millisecondsSinceEpoch}';
    return Success<AuthSession>(_buildSession(user));
  }

  @override
  Future<Result<void>> resendOtp({required String phone}) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> forgotPassword({required String identifier}) async =>
      const Success<void>(null);

  @override
  Future<Result<void>> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    if (newPassword.length < 6) {
      return const Failure<void>(
        ValidationException(message: 'Password must be at least 6 characters.'),
      );
    }
    return const Success<void>(null);
  }

  @override
  Future<Result<AuthSession?>> restoreSession() async {
    if (_currentUser == null || _accessToken == null) {
      return const Success<AuthSession?>(null);
    }
    return Success<AuthSession?>(_buildSession(_currentUser!));
  }

  @override
  Future<Result<void>> logout() async {
    _currentUser = null;
    _accessToken = null;
    return const Success<void>(null);
  }

  AuthSession _buildSession(User user) => AuthSession(
        accessToken: _accessToken ?? 'mock_access',
        refreshToken: 'mock_refresh',
        user: user,
      );
}
