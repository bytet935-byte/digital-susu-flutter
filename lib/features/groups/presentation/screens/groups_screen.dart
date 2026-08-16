import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../domain/group_models.dart';
import '../providers/groups_providers.dart';
import '../widgets/group_widgets.dart';

/// Groups tab (design reference "My Susu"): Active/Completed tabs, group
/// cards, create (FAB) and join actions.
class GroupsScreen extends ConsumerWidget {
  const GroupsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);
    final controller = ref.read(myGroupsProvider.notifier);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('My Susu'),
          actions: <Widget>[
            IconButton(
              tooltip: 'Join a group',
              icon: const Icon(Icons.person_add_alt_1_outlined),
              onPressed: () => context.go(AppRoutes.groupJoin),
            ),
          ],
          bottom: const TabBar(
            tabs: <Widget>[
              Tab(text: 'Active'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go(AppRoutes.groupCreate),
          backgroundColor: Theme.of(context).colorScheme.primary,
          foregroundColor: Colors.white,
          icon: const Icon(Icons.add),
          label: const Text('Create Susu'),
        ),
        body: groupsAsync.when(
          loading: () => const AppLoadingView(),
          error: (error, stackTrace) => AppErrorState(
            onRetry: controller.refresh,
          ),
          data: (groups) {
            final active =
                groups.where((g) => g.status == GroupStatuses.active).toList();
            final completed = groups
                .where((g) => g.status == GroupStatuses.completed)
                .toList();
            return TabBarView(
              children: <Widget>[
                _GroupList(
                  groups: active,
                  emptyTitle: 'No active susu groups',
                  emptyMessage:
                      'Create a new group or join one with an invite code.',
                  onTapGroup: (group) =>
                      context.go(AppRoutes.groupDetails(group.id)),
                ),
                _GroupList(
                  groups: completed,
                  emptyTitle: 'No completed groups yet',
                  emptyMessage:
                      'When a group finishes its cycles it will appear here.',
                  onTapGroup: (group) =>
                      context.go(AppRoutes.groupDetails(group.id)),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.groups,
    required this.emptyTitle,
    required this.emptyMessage,
    required this.onTapGroup,
  });

  final List<SusuGroup> groups;
  final String emptyTitle;
  final String emptyMessage;
  final ValueChanged<SusuGroup> onTapGroup;

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return AppEmptyState(title: emptyTitle, message: emptyMessage);
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: groups.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final group = groups[index];
        return GroupCard(group: group, onTap: () => onTapGroup(group));
      },
    );
  }
}
