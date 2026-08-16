import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/calculator/presentation/susu_calculator_sheet.dart';

void main() {
  testWidgets('computes pot, pooled total and your contribution',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SusuCalculatorSheet()),
    ));
    await tester.pumpAndSettle();

    // Defaults: GHS 100 × 10 members, 26 cycles.
    expect(find.text('Susu Calculator'), findsOneWidget);
    expect(find.text('GHS 1,000.00'), findsOneWidget); // pot per cycle
    expect(find.text('GHS 26,000.00'), findsOneWidget); // total pooled
    expect(find.text('GHS 2,600.00'), findsOneWidget); // your total
  });

  testWidgets('recalculates when members change', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(body: SusuCalculatorSheet()),
    ));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Increase Members'));
    await tester.pumpAndSettle();

    expect(find.text('GHS 1,100.00'), findsOneWidget); // 100 × 11
    expect(find.text('GHS 28,600.00'), findsOneWidget); // × 26
  });
}
