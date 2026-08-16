import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/authentication/domain/models/auth_session.dart';
import 'package:digital_susu/features/authentication/domain/models/user.dart';
import 'package:digital_susu/features/authentication/presentation/providers/auth_providers.dart';
import 'package:digital_susu/features/groups/data/mock_groups_repository.dart';
import 'package:digital_susu/features/groups/domain/group_models.dart';
import 'package:digital_susu/features/groups/presentation/providers/groups_providers.dart';
import 'package:digital_susu/features/groups/presentation/screens/group_chat_tab.dart';
import 'package:digital_susu/features/groups/presentation/screens/group_overview_tab.dart';
import 'package:digital_susu/features/groups/presentation/screens/groups_screen.dart';
import 'package:digital_susu/shared/models/money.dart';

Widget wrap(Widget child) => ProviderScope(
      overrides: <Override>[
        groupsRepositoryProvider.overrideWithValue(MockGroupsRepository()),
      ],
      // Scaffold supplies the Material ancestor TextFields require.
      child: MaterialApp(home: Scaffold(body: child)),
    );

/// Authenticated auth state so the chat composer can send as the demo user.
class _AuthedAuthState extends AuthStateNotifier {
  @override
  AuthState build() => AuthAuthenticated(AuthSession(
        accessToken: 'test-token',
        refreshToken: 'test-refresh',
        user: User(
          id: MockGroupsRepository.currentUserId,
          fullName: 'Kwame Owusu',
          phone: '0241234567',
          createdAt: DateTime(2026),
        ),
      ));
}

Widget wrapAuthed(Widget child) => ProviderScope(
      overrides: <Override>[
        groupsRepositoryProvider.overrideWithValue(MockGroupsRepository()),
        authStateProvider.overrideWith(_AuthedAuthState.new),
      ],
      // Scaffold supplies the Material ancestor TextFields require.
      child: MaterialApp(home: Scaffold(body: child)),
    );

void main() {
  group('GroupsScreen (design reference "My Susu")', () {
    testWidgets('renders active and completed groups', (tester) async {
      await tester.pumpWidget(wrap(const GroupsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Susu'), findsOneWidget);
      expect(find.text('Weekend Susu'), findsOneWidget);
      expect(find.text('Project Susu'), findsOneWidget);
      expect(find.text('Business Susu'), findsOneWidget);
      expect(find.text('Create Susu'), findsOneWidget);
    });

    testWidgets('completed tab lists completed groups', (tester) async {
      await tester.pumpWidget(wrap(const GroupsScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Completed'));
      await tester.pumpAndSettle();

      expect(find.text('Choir Savings'), findsOneWidget);
    });

    testWidgets('overview shows the my-contribution progress bar',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_weekend',
        name: 'Weekend Susu',
        type: GroupTypes.rotationalSusu,
        status: GroupStatuses.active,
        pot: Money(50000),
        memberCount: 10,
        totalMembers: 10,
        myContribution: Money(15000),
        myTarget: Money(50000),
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      expect(find.text('My Contribution'), findsOneWidget);
      expect(find.textContaining('150.00 of GH₵ 500.00'), findsOneWidget);
      expect(find.text('30% of target'), findsOneWidget);
    });

    testWidgets('rotational groups show the payout schedule card',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_weekend',
        name: 'Weekend Susu',
        type: GroupTypes.rotationalSusu,
        status: GroupStatuses.active,
        pot: Money(50000),
        memberCount: 10,
        totalMembers: 10,
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      expect(find.text('Payout Schedule'), findsOneWidget);
      expect(find.text('Cycle 12 of 26'), findsOneWidget);
      expect(find.text('Ama Serwaa'), findsOneWidget);

      // The footer is below the fold in the lazy ListView — scroll to it.
      await tester.scrollUntilVisible(
        find.textContaining('per cycle'),
        200,
      );
      expect(find.textContaining('GH₵ 100.00 per cycle'), findsOneWidget);
    });

    testWidgets('savings-goal groups hide the payout schedule card',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_project',
        name: 'Project Susu',
        type: GroupTypes.savingsGoal,
        status: GroupStatuses.active,
        pot: Money(75000),
        memberCount: 15,
        totalMembers: 15,
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      expect(find.text('Payout Schedule'), findsNothing);
    });

    testWidgets('savings-goal groups show the goal progress card',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_project',
        name: 'Project Susu',
        type: GroupTypes.savingsGoal,
        status: GroupStatuses.active,
        pot: Money(75000),
        memberCount: 15,
        totalMembers: 15,
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      expect(find.text('Goal Progress'), findsOneWidget);
      expect(find.text('GH₵ 2,000.00 goal'), findsOneWidget);
      expect(
        find.textContaining('GH₵ 750.00 of GH₵ 2,000.00'),
        findsOneWidget,
      );
      // Pot GHS 750 has passed the GHS 500 milestone only.
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
      expect(find.byIcon(Icons.radio_button_unchecked), findsNWidgets(3));
    });

    testWidgets('rotational groups hide the goal progress card',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_weekend',
        name: 'Weekend Susu',
        type: GroupTypes.rotationalSusu,
        status: GroupStatuses.active,
        pot: Money(50000),
        memberCount: 10,
        totalMembers: 10,
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      expect(find.text('Goal Progress'), findsNothing);
    });

    testWidgets('savings-goal groups hide the payout schedule card',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_project',
        name: 'Project Susu',
        type: GroupTypes.savingsGoal,
        status: GroupStatuses.active,
        pot: Money(75000),
        memberCount: 15,
        totalMembers: 15,
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      expect(find.text('Rotational Susu'), findsNothing);
    });

    testWidgets('Contribute Now opens the sheet and records a contribution',
        (tester) async {
      const group = SusuGroup(
        id: 'grp_weekend',
        name: 'Weekend Susu',
        type: GroupTypes.rotationalSusu,
        status: GroupStatuses.active,
        pot: Money(50000),
        memberCount: 10,
        totalMembers: 10,
      );
      await tester.pumpWidget(wrap(const GroupOverviewTab(group: group)));
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Contribute Now'), 200);
      await tester.tap(find.text('Contribute Now'));
      await tester.pumpAndSettle();

      expect(find.text('Contribute to Weekend Susu'), findsOneWidget);
      expect(find.text('Pot: GHS 500.00'), findsOneWidget);

      await tester.tap(find.widgetWithText(ChoiceChip, 'GHS 50'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
      await tester.pumpAndSettle();

      expect(find.text('Contribution recorded 🎉'), findsOneWidget);
    });
  });

  group('GroupChatTab (build spec §10, design reference)', () {
    testWidgets('renders the conversation and composer', (tester) async {
      await tester.pumpWidget(wrap(const GroupChatTab(
        groupId: 'grp_weekend',
        currentUserId: MockGroupsRepository.currentUserId,
      )));
      await tester.pumpAndSettle();

      expect(find.text('Ama Serwaa'), findsWidgets);
      expect(find.text('Good evening everyone 🌙 Don\'t forget tomorrow\'s contribution.'),
          findsOneWidget);
      expect(find.text('Type a message…'), findsOneWidget);
    });

    testWidgets('sending a message appends it to the conversation',
        (tester) async {
      await tester.pumpWidget(wrapAuthed(const GroupChatTab(
        groupId: 'grp_weekend',
        currentUserId: MockGroupsRepository.currentUserId,
      )));
      await tester.pumpAndSettle();

      await tester.enterText(
          find.widgetWithText(TextField, 'Type a message…'), 'Hello team');
      await tester.tap(find.byIcon(Icons.send));
      await tester.pumpAndSettle();

      expect(find.text('Hello team'), findsOneWidget);
    });
  });
}
