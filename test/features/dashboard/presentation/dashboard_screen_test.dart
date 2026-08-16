import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/authentication/domain/models/auth_session.dart';
import 'package:digital_susu/features/authentication/domain/models/user.dart';
import 'package:digital_susu/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_susu/features/dashboard/presentation/screens/dashboard_screen.dart';

/// Authenticated auth state so the dashboard renders the demo user.
class _AuthedAuthState extends AuthStateNotifier {
  @override
  AuthState build() => AuthAuthenticated(AuthSession(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        user: User(
          id: 'usr_kwame',
          fullName: 'Kwame Owusu',
          phone: '0241234567',
          kycStatus: 'VERIFIED',
          createdAt: DateTime(2026),
        ),
      ));
}

Widget wrap() => ProviderScope(
      overrides: <Override>[
        authStateProvider.overrideWith(_AuthedAuthState.new),
      ],
      child: const MaterialApp(home: DashboardScreen()),
    );

void main() {
  testWidgets('renders the regular dashboard', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Hello, Kwame 👋'), findsOneWidget);
    expect(find.text('GHS 1,250.00'), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);
    expect(find.text('My Susu'), findsOneWidget);
    expect(find.text('Weekend Susu'), findsOneWidget);
  });

  testWidgets('elder-friendly mode toggles to the large-button layout',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    // Toggle via the accessibility icon in the header.
    await tester.tap(find.byTooltip('Elder-friendly mode'));
    await tester.pumpAndSettle();

    expect(find.text('YOUR MONEY'), findsOneWidget);
    expect(find.text('DEPOSIT'), findsOneWidget);
    expect(find.text('WITHDRAW'), findsOneWidget);
    expect(find.text('SEND'), findsOneWidget);
    // The regular layout is gone.
    expect(find.text('Top Up'), findsNothing);
    expect(find.text('My Susu'), findsNothing);

    // Toggling back restores the regular layout.
    await tester.tap(find.byTooltip('Elder-friendly mode on'));
    await tester.pumpAndSettle();
    expect(find.text('Top Up'), findsOneWidget);
  });
}
