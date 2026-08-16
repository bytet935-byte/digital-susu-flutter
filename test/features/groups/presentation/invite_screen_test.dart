import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/groups/data/mock_groups_repository.dart';
import 'package:digital_susu/features/groups/presentation/providers/groups_providers.dart';
import 'package:digital_susu/features/groups/presentation/screens/invite_screen.dart';

Widget wrap() => ProviderScope(
      overrides: <Override>[
        groupsRepositoryProvider.overrideWithValue(MockGroupsRepository()),
      ],
      child: const MaterialApp(home: InviteScreen()),
    );

void main() {
  testWidgets('lists active groups with their invite codes', (tester) async {
    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    expect(find.text('Invite Friends'), findsOneWidget);
    expect(find.text('Weekend Susu'), findsOneWidget);
    expect(find.text('SUSU-4821'), findsOneWidget);
    expect(find.text('Project Susu'), findsOneWidget);
    expect(find.text('SUSU-7395'), findsOneWidget);
    // Completed groups are not inviteable.
    expect(find.text('Choir Savings'), findsNothing);
  });

  testWidgets('copy puts the code on the clipboard and confirms',
      (tester) async {
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

    await tester.pumpWidget(wrap());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Copy').first);
    await tester.pumpAndSettle();

    expect(
      log.any(
        (MethodCall call) =>
            call.method == 'Clipboard.setData' &&
            (call.arguments as Map<Object?, Object?>)['text'] ==
                'SUSU-4821',
      ),
      isTrue,
    );
    expect(find.textContaining('Invite code SUSU-4821 copied'), findsOneWidget);
  });
}
