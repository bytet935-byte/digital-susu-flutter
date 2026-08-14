import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/authentication/presentation/screens/forgot_password_screen.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/authentication/presentation/screens/otp_screen.dart';
import '../../features/authentication/presentation/screens/register_screen.dart';
import '../../features/authentication/presentation/screens/reset_password_screen.dart';
import '../../features/authentication/presentation/screens/splash_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import 'app_routes.dart';

/// Centralized router (spec §30).
///
/// Guarding is session-based: [AuthUnknown] keeps the splash visible while
/// the session restores, unauthenticated users are restricted to public
/// routes, and authenticated users land on the dashboard. The router listens
/// to auth-state transitions and navigates accordingly (login → dashboard,
/// logout/session-expiry → login). Permission-specific guards are layered on
/// per-feature from Phase 5.
final routerProvider = Provider<GoRouter>((ref) {
  final router = GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final auth = ref.read(authStateProvider);
      final isPublic = AppRoutes.publicRoutes.contains(state.matchedLocation);
      return switch (auth) {
        AuthUnknown() => isPublic ? null : AppRoutes.splash,
        AuthUnauthenticated() => isPublic ? null : AppRoutes.login,
        AuthAuthenticated() => isPublic ? AppRoutes.dashboard : null,
      };
    },
    errorBuilder: (context, state) => const _RouteErrorScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.register,
        name: 'register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) => OtpScreen(
          phone: state.uri.queryParameters['phone'] ?? '',
          flow: state.uri.queryParameters['flow'] ?? 'register',
        ),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        name: 'reset-password',
        builder: (context, state) => ResetPasswordScreen(
          identifier: state.uri.queryParameters['identifier'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );

  // React to auth-state transitions: signed-in → dashboard, signed-out →
  // login (covers login success, logout and session expiry).
  ref.listen<AuthState>(authStateProvider, (previous, next) {
    if (previous == next) return;
    if (next is AuthAuthenticated) {
      router.go(AppRoutes.dashboard);
    } else if (next is AuthUnauthenticated) {
      router.go(AppRoutes.login);
    }
  });

  return router;
});

/// Fallback shown when a route has no screen yet (feature pending a phase).
class _RouteErrorScreen extends StatelessWidget {
  const _RouteErrorScreen();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(
                Icons.signpost_outlined,
                size: 56,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 16),
              Text(
                'This screen is not ready yet',
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'The feature is planned for an upcoming phase.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.login),
                icon: const Icon(Icons.home_outlined),
                label: const Text('Go to login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
