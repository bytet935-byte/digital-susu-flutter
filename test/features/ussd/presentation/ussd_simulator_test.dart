import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/ussd/presentation/ussd_simulator.dart';

void main() {
  testWidgets('responds to preset *713# codes', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showUssdSimulator(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '*713*1#');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(
      find.text('Your wallet balance is GHS 1,250.00.'),
      findsOneWidget,
    );
  });

  testWidgets('rejects unknown codes with guidance', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => Center(
            child: ElevatedButton(
              onPressed: () => showUssdSimulator(context),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ));

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '*999#');
    await tester.tap(find.text('Send'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('Invalid code'),
      findsOneWidget,
    );
  });
}
