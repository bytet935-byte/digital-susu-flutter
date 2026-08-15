import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../domain/group_models.dart';
import '../providers/groups_providers.dart';
import 'group_chat_tab.dart';
import 'group_members_tab.dart';
import 'group_overview_tab.dart';

/// Group details screen (build spec §9): header + Overview / Members / Chat
/// tabs, matching the design reference "Susu Details".
class GroupDetailsScreen extends ConsumerWidget {
  const GroupDetailsScreen({super.key, required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupAsync = ref.watch(groupDetailsProvider(groupId));

    return groupAsync.when(
      loading: () => Scaffold(
        appBar: AppBar(),
        body: const AppLoadingView(message: 'Loading group…'),
      ),
      error: (error, stackTrace) => Scaffold(
        appBar: AppBar(),
        body: AppErrorState(
          onRetry: () => ref.invalidate(groupDetailsProvider(groupId)),
        ),
      ),
      data: (group) {
        final auth = ref.watch(authStateProvider);
        final currentUserId = switch (auth) {
          AuthAuthenticated(:final session) => session.user.id,
          _ => '',
        };
        return DefaultTabController(
          length: 3,
          child: Scaffold(
            appBar: AppBar(
              title: Text(group.name),
              actions: <Widget>[
                IconButton(
                  tooltip: 'Group chat',
                  icon: const Icon(Icons.chat_bubble_outline),
                  onPressed: () => _openChat(context, group),
                ),
              ],
              bottom: const TabBar(
                tabs: <Widget>[
                  Tab(text: 'Overview'),
                  Tab(text: 'Members'),
                  Tab(text: 'Chat'),
                ],
              ),
            ),
            body: TabBarView(
              children: <Widget>[
                GroupOverviewTab(group: group),
                GroupMembersTab(groupId: group.id, currentUserId: currentUserId),
                GroupChatTab(groupId: group.id, currentUserId: currentUserId),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openChat(BuildContext context, SusuGroup group) {
    // Chat lives in the third tab; switch to it by setting the controller.
    DefaultTabController.of(context).animateTo(2);
  }
}
