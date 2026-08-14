import '../../../../core/utils/result.dart';
import '../models/auth_session.dart';
import '../models/user.dart';

/// Authentication repository contract (spec §10, FLOW 1).
///
/// Implementations: `MockAuthRepository` (USE_MOCK_DATA=true) and
/// `ApiAuthRepository` (real backend). Both return `Result<T>` so callers
/// handle failures explicitly.
abstract interface class AuthRepository {
  /// Password login with phone or email.
  Future<Result<AuthSession>> login({
    required String identifier,
    required String password,
  });

  /// Creates an account; the user must then verify the 6-digit OTP
  /// ([verifyOtp]) before the session activates (FLOW 1).
  Future<Result<User>> register({
    required String fullName,
    required String identifier,
    required String password,
  });

  /// Completes verification and activates the session.
  Future<Result<AuthSession>> verifyOtp({
    required String phone,
    required String code,
  });

  Future<Result<void>> resendOtp({required String phone});

  Future<Result<void>> forgotPassword({required String identifier});

  Future<Result<void>> resetPassword({
    required String code,
    required String newPassword,
  });

  /// Restores a persisted session at app start; returns `null` when the user
  /// is logged out.
  Future<Result<AuthSession?>> restoreSession();

  Future<Result<void>> logout();
}
