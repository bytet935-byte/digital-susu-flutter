import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/wallet/data/mock_wallet_repository.dart';
import 'package:digital_susu/features/wallet/presentation/providers/wallet_providers.dart';
import 'package:digital_susu/features/wallet/presentation/screens/wallet_screen.dart';

Widget wrap() => ProviderScope(
      overrides: <Override>[
        walletRepositoryProvider.overrideWithValue(MockWalletRepository()),
      ],
      child: const MaterialApp(home: WalletScreen()),
    );

void main() {
  testWidgets('renders balance, actions and recent transactions',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('GHS 1,250.00'), findsOneWidget);
    expect(find.text('Top Up'), findsOneWidget);
    expect(find.text('Withdraw'), findsOneWidget);
    expect(find.text('Add Money'), findsOneWidget);
    expect(find.text('Send Money'), findsOneWidget);
    expect(find.text('Bank Transfer'), findsOneWidget);
    expect(find.text('Airtime'), findsOneWidget);
    expect(find.text('Weekend Susu contribution'), findsOneWidget);
    expect(find.text('Wallet top-up'), findsOneWidget);
  });

  testWidgets('top up flow updates the balance through the amount sheet',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Top Up'));
    await tester.pumpAndSettle();

    expect(find.text('Top Up Wallet'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '50');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(FilledButton, 'Top Up'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('GHS 1,300.00'), findsOneWidget);
    expect(find.text('Wallet topped up successfully'), findsOneWidget);
  });

  testWidgets('withdraw validates against the available balance',
      (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Withdraw'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '5000');
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(
      of: find.byType(BottomSheet),
      matching: find.widgetWithText(FilledButton, 'Withdraw'),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Amount exceeds your available balance'), findsOneWidget);
  });
}
