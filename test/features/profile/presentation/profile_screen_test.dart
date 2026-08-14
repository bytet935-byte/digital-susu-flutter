import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:digital_susu/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_susu/features/profile/presentation/screens/profile_screen.dart';

void main() {
  Future<ProviderContainer> authenticatedContainer() async {
    final container = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(container.dispose);
    await container.read(authControllerProvider.notifier).login(
          identifier: '0241234567',
          password: '123456',
        );
    return container;
  }

  group('ProfileScreen (spec §22, design reference)', () {
    testWidgets('renders the logged-in user profile', (tester) async {
      final container = await authenticatedContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Kwame Owusu'), findsOneWidget);
      expect(find.text('+233 24 123 4567'), findsOneWidget);
      expect(find.text('KYC: PENDING'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('shows logout confirmation dialog', (tester) async {
      final container = await authenticatedContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('confirming logout returns to unauthenticated', (tester) async {
      final container = await authenticatedContainer();
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: ProfileScreen()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Log Out'));
      await tester.pumpAndSettle();

      expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
    });
  });
}
