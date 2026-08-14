import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/authentication/presentation/providers/auth_providers.dart';
import '../../features/authentication/presentation/screens/login_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import 'app_routes.dart';

/// Centralized router (spec §30).
///
/// Route guarding is session-based in Phase 1; permission-specific guards are
/// layered on per-feature from Phase 3/5. Feature routes are registered as
/// their phases land — paths already exist in [AppRoutes].
final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.login,
    redirect: (context, state) {
      final isAuthenticated = ref.read(authStateProvider);
      final isPublic = AppRoutes.publicRoutes.contains(state.matchedLocation);
      if (!isAuthenticated && !isPublic) {
        return AppRoutes.login;
      }
      if (isAuthenticated && isPublic) {
        return AppRoutes.dashboard;
      }
      return null;
    },
    errorBuilder: (context, state) => const _RouteErrorScreen(),
    routes: <RouteBase>[
      GoRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.dashboard,
        name: 'dashboard',
        builder: (context, state) => const DashboardScreen(),
      ),
    ],
  );
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
