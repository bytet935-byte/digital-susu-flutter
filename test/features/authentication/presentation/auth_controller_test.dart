import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:digital_susu/features/authentication/presentation/providers/auth_providers.dart';

void main() {
  late ProviderContainer container;

  ProviderContainer buildContainer() {
    final c = ProviderContainer(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
    );
    addTearDown(c.dispose);
    return c;
  }

  setUp(() {
    container = buildContainer();
  });

  group('AuthController — session restore (spec §10)', () {
    test('starts unauthenticated without a persisted session', () async {
      final session = await container.read(authControllerProvider.future);
      expect(session, isNull);
      expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
    });
  });

  group('AuthController — login', () {
    test('successful login sets authenticated state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login(
        identifier: '0241234567',
        password: '123456',
      );

      final state = container.read(authStateProvider);
      expect(state, isA<AuthAuthenticated>());
      expect((state as AuthAuthenticated).session.user.fullName, 'Kwame Owusu');
      expect(container.read(authControllerProvider).valueOrNull, isNotNull);
    });

    test('failed login surfaces a friendly exception', () async {
      final controller = container.read(authControllerProvider.notifier);
      await expectLater(
        controller.login(identifier: '0241234567', password: 'wrong'),
        throwsA(isA<ValidationException>()),
      );
      expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
    });
  });

  group('AuthController — registration flow (FLOW 1)', () {
    test('register → verifyOtp → authenticated', () async {
      final controller = container.read(authControllerProvider.notifier);
      final user = await controller.register(
        fullName: 'Ama Serwaa',
        identifier: '0551234567',
        password: 'secret1',
      );
      expect(user.phone, '0551234567');
      expect(container.read(authStateProvider), isA<AuthUnauthenticated>());

      await controller.verifyOtp(phone: '0551234567', code: '123456');
      expect(container.read(authStateProvider), isA<AuthAuthenticated>());
    });
  });

  group('AuthController — logout & session expiry', () {
    test('logout returns to unauthenticated', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login(
        identifier: '0241234567',
        password: '123456',
      );
      expect(container.read(authStateProvider), isA<AuthAuthenticated>());

      await controller.logout();
      expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
      expect(container.read(authControllerProvider).valueOrNull, isNull);
    });

    test('forceLogout handles network-level session expiry', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.login(
        identifier: '0241234567',
        password: '123456',
      );

      controller.forceLogout();
      expect(container.read(authStateProvider), isA<AuthUnauthenticated>());
    });
  });
}
