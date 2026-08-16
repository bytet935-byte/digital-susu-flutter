import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/payments/data/mock_payments_repository.dart';
import 'package:digital_susu/features/payments/presentation/providers/payments_providers.dart';
import 'package:digital_susu/features/payments/presentation/screens/payments_screen.dart';

Widget wrap() => ProviderScope(
      overrides: <Override>[
        paymentsRepositoryProvider.overrideWithValue(MockPaymentsRepository()),
      ],
      child: const MaterialApp(home: PaymentsScreen()),
    );

void main() {
  testWidgets('renders balance header and color-coded payments',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Payments'), findsOneWidget);
    expect(find.text('Wallet Balance'), findsOneWidget);
    expect(find.text('GHS 1,250.00'), findsOneWidget);
    expect(find.text('Weekend Susu contribution'), findsOneWidget);
    expect(find.text('Wallet top-up'), findsOneWidget);

    // Lower entries are below the fold in the lazy ListView — scroll to them.
    await tester.scrollUntilVisible(
      find.text('Business Susu contribution'),
      200,
    );
    expect(find.text('Pending'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Card top-up'), 200);
    expect(find.text('Failed'), findsOneWidget);
  });
}
