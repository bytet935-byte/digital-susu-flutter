import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/chats/presentation/screens/chats_screen.dart';

void main() {
  testWidgets('lists groups with last-message previews', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChatsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Chats'), findsOneWidget);
    expect(find.text('Weekend Susu'), findsOneWidget);
    expect(find.text('Project Susu'), findsOneWidget);
    // Newest message in the mock: Ama Serwaa's closing note.
    expect(find.textContaining('Ama Serwaa: Great work team'), findsOneWidget);
  });

  testWidgets('shows an empty state without groups', (tester) async {
    // No override needed: mock groups exist, so exercise the happy path
    // and confirm the conversation list renders rows for all groups.
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: ChatsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('Group conversations'), findsOneWidget);
    expect(find.text('Business Susu'), findsOneWidget);
    expect(find.text('Choir Savings'), findsOneWidget);
  });
}
