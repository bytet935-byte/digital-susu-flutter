import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/authentication/data/repositories/mock_auth_repository.dart';
import 'package:digital_susu/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_susu/features/authentication/presentation/screens/login_screen.dart';
import 'package:digital_susu/features/authentication/presentation/screens/otp_screen.dart';
import 'package:digital_susu/features/authentication/presentation/screens/register_screen.dart';

Widget wrap(Widget child) => ProviderScope(
      overrides: <Override>[
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
      ],
      child: MaterialApp(home: child),
    );

void main() {
  group('LoginScreen', () {
    testWidgets('renders design-reference content (spec §31)', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen()));

      expect(find.text('Welcome Back 👋'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Login'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
    });

    testWidgets('shows validation errors on empty submit', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen()));

      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Enter your email or phone number'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('demo credentials submit without crashing', (tester) async {
      await tester.pumpWidget(wrap(const LoginScreen()));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or Phone Number'),
          '0241234567');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), '123456');
      await tester.tap(find.text('Login'));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back 👋'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('renders registration fields', (tester) async {
      await tester.pumpWidget(wrap(const RegisterScreen()));

      expect(find.text('Create Account'), findsOneWidget);
      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Email or Phone Number'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('I agree to the Terms & Conditions'), findsOneWidget);
    });

    testWidgets('requires terms acceptance', (tester) async {
      await tester.pumpWidget(wrap(const RegisterScreen()));

      await tester.enterText(
          find.widgetWithText(TextFormField, 'Full Name'), 'Ama Serwaa');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Email or Phone Number'),
          '0551234567');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Password'), 'secret1');
      await tester.enterText(
          find.widgetWithText(TextFormField, 'Confirm Password'), 'secret1');
      await tester.tap(find.text('Sign Up'));
      await tester.pump();

      expect(find.text('Please accept the Terms & Conditions to continue.'),
          findsOneWidget);
    });
  });

  group('OtpScreen', () {
    testWidgets('renders OTP entry (6-digit)', (tester) async {
      await tester.pumpWidget(wrap(const OtpScreen(phone: '0241234567')));

      expect(find.text('Enter the 6-digit code'), findsOneWidget);
      expect(find.text('Verify'), findsOneWidget);
      expect(find.text('Resend'), findsOneWidget);
    });
  });
}
