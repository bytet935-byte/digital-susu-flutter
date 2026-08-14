import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/errors/app_exception.dart';
import 'package:digital_susu/core/utils/result.dart';
import 'package:digital_susu/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:digital_susu/features/authentication/domain/models/auth_session.dart';
import 'package:digital_susu/features/authentication/domain/models/user.dart';

void main() {
  late MockAuthRepository repo;

  setUp(() {
    repo = MockAuthRepository();
  });

  group('MockAuthRepository — login', () {
    test('demo account logs in (FLOW 1)', () async {
      final result = await repo.login(
        identifier: '0241234567',
        password: '123456',
      );
      expect(result, isA<Success<AuthSession>>());
      final session = (result as Success<AuthSession>).value;
      expect(session.user.fullName, 'Kwame Owusu');
      expect(session.accessToken, isNotEmpty);
    });

    test('wrong password fails with a friendly error', () async {
      final result = await repo.login(
        identifier: '0241234567',
        password: 'wrong',
      );
      expect(result, isA<Failure<AuthSession>>());
      expect((result as Failure<AuthSession>).error,
          isA<ValidationException>());
    });

    test('unknown identifier fails', () async {
      final result = await repo.login(
        identifier: '0550000000',
        password: '123456',
      );
      expect(result, isA<Failure<AuthSession>>());
    });
  });

  group('MockAuthRepository — registration + OTP', () {
    test('register → verifyOtp → active session (FLOW 1)', () async {
      final registered = await repo.register(
        fullName: 'Ama Serwaa',
        identifier: '0551234567',
        password: 'secret1',
      );
      expect(registered, isA<Success<User>>());

      final verified = await repo.verifyOtp(phone: '0551234567', code: '123456');
      expect(verified, isA<Success<AuthSession>>());
      expect((verified as Success<AuthSession>).value.user.fullName,
          'Ama Serwaa');
    });

    test('invalid OTP is rejected', () async {
      await repo.register(
        fullName: 'Ama Serwaa',
        identifier: '0551234567',
        password: 'secret1',
      );
      final verified = await repo.verifyOtp(phone: '0551234567', code: '12ab');
      expect(verified, isA<Failure<AuthSession>>());
    });

    test('short passwords are rejected', () async {
      final result = await repo.register(
        fullName: 'Ama Serwaa',
        identifier: '0551234567',
        password: '123',
      );
      expect(result, isA<Failure<User>>());
    });
  });

  group('MockAuthRepository — session lifecycle', () {
    test('restoreSession is null before login and after logout', () async {
      expect((await repo.restoreSession()).valueOrNull, isNull);

      await repo.login(identifier: '0241234567', password: '123456');
      expect((await repo.restoreSession()).valueOrNull, isNotNull);

      await repo.logout();
      expect((await repo.restoreSession()).valueOrNull, isNull);
    });

    test('forgot/reset password succeed', () async {
      expect((await repo.forgotPassword(identifier: '0241234567')).isSuccess,
          isTrue);
      expect(
        (await repo.resetPassword(code: '123456', newPassword: 'newpass1'))
            .isSuccess,
        isTrue,
      );
      expect(
        (await repo.resetPassword(code: '123456', newPassword: '123'))
            .isFailure,
        isTrue,
      );
    });
  });
}
