import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Authentication session state — drives route guarding (spec §10, §30).
///
/// Phase 1 keeps a hard-coded `false` session so the router only exposes
/// public routes. Phase 3 replaces [AuthStateNotifier.build] with real session
/// restoration from secure storage and wires login/logout.
final authStateProvider = NotifierProvider<AuthStateNotifier, bool>(
  AuthStateNotifier.new,
);

class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void setAuthenticated(bool value) => state = value;

  /// Clears the session (logout / session expiry).
  void clearSession() => state = false;
}
