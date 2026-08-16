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
import '../../features/groups/presentation/screens/create_group_screen.dart';
import '../../features/groups/presentation/screens/group_details_screen.dart';
import '../../features/groups/presentation/screens/groups_screen.dart';
import '../../features/groups/presentation/screens/invite_screen.dart';
import '../../features/groups/presentation/screens/join_group_screen.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/payments/presentation/screens/payments_screen.dart';
import '../../features/profile/presentation/screens/edit_profile_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/transactions/presentation/screens/transactions_screen.dart';
import '../../features/wallet/presentation/screens/wallet_screen.dart';
import '../../shared/widgets/main_shell.dart';
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
      // Authenticated app shell: Home · Groups · [+] · Wallet · Profile
      // (design reference bottom navigation, spec §31).
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: <StatefulShellBranch>[
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.dashboard,
                name: 'dashboard',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.groups,
                name: 'groups',
                builder: (context, state) => const GroupsScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.wallet,
                name: 'wallet',
                builder: (context, state) => const WalletScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: <RouteBase>[
              GoRoute(
                path: AppRoutes.profile,
                name: 'profile',
                builder: (context, state) => const ProfileScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.groupDetailsTemplate,
        name: 'group-details',
        builder: (context, state) => GroupDetailsScreen(
          groupId: state.pathParameters['groupId'] ?? '',
        ),
      ),
      GoRoute(
        path: AppRoutes.groupCreate,
        name: 'group-create',
        builder: (context, state) => const CreateGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.groupJoin,
        name: 'group-join',
        builder: (context, state) => const JoinGroupScreen(),
      ),
      GoRoute(
        path: AppRoutes.notifications,
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: AppRoutes.transactions,
        name: 'transactions',
        builder: (context, state) => const TransactionsScreen(),
      ),
      GoRoute(
        path: AppRoutes.payments,
        name: 'payments',
        builder: (context, state) => const PaymentsScreen(),
      ),
      GoRoute(
        path: AppRoutes.invite,
        name: 'invite',
        builder: (context, state) => const InviteScreen(),
      ),
      GoRoute(
        path: AppRoutes.settings,
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEdit,
        name: 'profile-edit',
        builder: (context, state) => const EditProfileScreen(),
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
