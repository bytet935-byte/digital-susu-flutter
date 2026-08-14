import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/shared/widgets/app_states.dart';

void main() {
  group('AppEmptyState', () {
    testWidgets('renders title, message and optional action', (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: AppEmptyState(
            title: 'No groups yet',
            message: 'Create your first susu group',
          ),
        ),
      ));

      expect(find.text('No groups yet'), findsOneWidget);
      expect(find.text('Create your first susu group'), findsOneWidget);
    });
  });

  group('AppErrorState', () {
    testWidgets('shows friendly message and triggers retry (spec §32)',
        (tester) async {
      var retried = false;
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: AppErrorState(
            message: 'Could not load your savings',
            onRetry: () => retried = true,
          ),
        ),
      ));

      expect(find.text('Could not load your savings'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      expect(retried, isTrue);
    });

    testWidgets('renders without a retry button when no handler is given',
        (tester) async {
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(body: AppErrorState()),
      ));

      expect(find.text('Something went wrong. Please try again.'),
          findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });
  });
}
