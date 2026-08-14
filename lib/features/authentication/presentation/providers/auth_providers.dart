import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/app_providers.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../../data/repositories/api_auth_repository.dart';
import '../../data/repositories/mock_auth_repository.dart';
import '../../domain/models/auth_session.dart';
import '../../domain/models/user.dart';
import '../../domain/repositories/auth_repository.dart';

// ---------------------------------------------------------------------------
// Auth state (router gate)
// ---------------------------------------------------------------------------

/// Session state machine used by the router guard (spec §10, §30).
sealed class AuthState {
  const AuthState();
}

/// Session restoration in progress at app start.
final class AuthUnknown extends AuthState {
  const AuthUnknown();
}

final class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.session);

  final AuthSession session;
}

final class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

final authStateProvider =
    NotifierProvider<AuthStateNotifier, AuthState>(AuthStateNotifier.new);

class AuthStateNotifier extends Notifier<AuthState> {
  @override
  AuthState build() => const AuthUnknown();

  void setAuthenticated(AuthSession session) =>
      state = AuthAuthenticated(session);

  void setUnauthenticated() => state = const AuthUnauthenticated();
}

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// Switches between mock and API auth backend via USE_MOCK_DATA (spec §11).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final api = ApiAuthRepository(
    client: ref.watch(apiClientProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    secureStorage: ref.watch(secureStorageProvider),
  );
  return selectRepository<AuthRepository>(
    mock: MockAuthRepository(),
    api: api,
  );
});

// ---------------------------------------------------------------------------
// Controller (UI flows)
// ---------------------------------------------------------------------------

/// Orchestrates authentication flows (FLOW 1): login / register → OTP →
/// session. `build()` restores a persisted session at app start.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, AuthSession?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<AuthSession?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  AuthStateNotifier get _authState => ref.read(authStateProvider.notifier);

  @override
  Future<AuthSession?> build() async {
    final result = await _repo.restoreSession();
    final session = result.valueOrNull;
    if (session != null) {
      _authState.setAuthenticated(session);
    } else {
      _authState.setUnauthenticated();
    }
    return session;
  }

  /// Password login. On success the router listener navigates to the
  /// dashboard. Throws the mapped [AppException] on failure.
  Future<void> login({
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.login(
      identifier: identifier,
      password: password,
    );
    switch (result) {
      case Success<AuthSession>(:final value):
        _authState.setAuthenticated(value);
        state = AsyncData(value);
      case Failure<AuthSession>(:final error):
        state = AsyncError(error, StackTrace.current);
        throw error;
    }
  }

  /// Registers a new account and returns the created user; the flow then
  /// proceeds to OTP verification. Throws on failure.
  Future<User> register({
    required String fullName,
    required String identifier,
    required String password,
  }) async {
    state = const AsyncLoading();
    final result = await _repo.register(
      fullName: fullName,
      identifier: identifier,
      password: password,
    );
    switch (result) {
      case Success<User>(:final value):
        state = AsyncData(state.valueOrNull);
        return value;
      case Failure<User>(:final error):
        state = AsyncError(error, StackTrace.current);
        throw error;
    }
  }

  /// Completes OTP verification and activates the session.
  Future<void> verifyOtp({
    required String phone,
    required String code,
  }) async {
    state = const AsyncLoading();
    final result =
        await _repo.verifyOtp(phone: phone, code: code);
    switch (result) {
      case Success<AuthSession>(:final value):
        _authState.setAuthenticated(value);
        state = AsyncData(value);
      case Failure<AuthSession>(:final error):
        state = AsyncError(error, StackTrace.current);
        throw error;
    }
  }

  Future<void> resendOtp({required String phone}) async {
    final result = await _repo.resendOtp(phone: phone);
    if (result is Failure<void>) throw result.error;
  }

  Future<void> forgotPassword({required String identifier}) async {
    final result = await _repo.forgotPassword(identifier: identifier);
    if (result is Failure<void>) throw result.error;
  }

  Future<void> resetPassword({
    required String code,
    required String newPassword,
  }) async {
    final result = await _repo.resetPassword(
      code: code,
      newPassword: newPassword,
    );
    if (result is Failure<void>) throw result.error;
  }

  /// Signs out locally and on the backend.
  Future<void> logout() async {
    await _repo.logout();
    _authState.setUnauthenticated();
    state = const AsyncData(null);
  }

  /// Local sign-out triggered by session expiry from the network layer
  /// (refresh failure). The router listener sends the user to login.
  void forceLogout() {
    _authState.setUnauthenticated();
    state = const AsyncData(null);
  }
}

/// Wired into the network layer's `sessionExpiredHandlerProvider` (in
/// main.dart) so a failed token refresh signs the user out app-wide.
final authSessionExpiryHandlerProvider = Provider<void Function()>((ref) {
  return () {
    // Deferred read — no build-time dependency on the controller.
    ref.read(authControllerProvider.notifier).forceLogout();
  };
});
