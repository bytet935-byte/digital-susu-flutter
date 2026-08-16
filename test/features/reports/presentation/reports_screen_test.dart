import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/reports/presentation/screens/reports_screen.dart';

void main() {
  testWidgets('summarises wallet, susu pots and contributions',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReportsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Reports'), findsOneWidget);
    expect(find.text('Wallet balance'), findsOneWidget);
    expect(find.text('GHS 1,250.00'), findsOneWidget); // wallet
    expect(find.text('In susu groups'), findsOneWidget);
    // 500 + 720 + 1,200 (active pots only; completed excluded).
    expect(find.text('GHS 2,420.00'), findsOneWidget);
    expect(find.text('My contributions'), findsOneWidget);
    // 150 + 75 + 240.
    expect(find.text('GHS 465.00'), findsOneWidget);
    // Recent activity from the payments ledger.
    expect(find.text('Weekend Susu contribution'), findsOneWidget);
  });

  testWidgets('export copies the report to the clipboard', (tester) async {
    final List<MethodCall> log = <MethodCall>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (MethodCall call) async {
        log.add(call);
        return null;
      },
    );
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ReportsScreen())),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Export'));
    await tester.pumpAndSettle();

    final setData = log
        .where((MethodCall c) => c.method == 'Clipboard.setData')
        .toList();
    expect(setData, hasLength(1));
    final text = (setData.single.arguments as Map<Object?, Object?>)['text']
        as String;
    expect(text, contains('Digital Susu Report'));
    expect(text, contains('Wallet balance: GHS 1,250.00'));
    expect(text, contains('In susu groups: GHS 2,420.00'));
    expect(text, contains('Weekend Susu contribution'));
    expect(find.textContaining('Report copied to clipboard'), findsOneWidget);
  });
}
