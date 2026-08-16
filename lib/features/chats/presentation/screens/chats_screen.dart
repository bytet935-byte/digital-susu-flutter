import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/routing/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../groups/domain/group_models.dart';
import '../../../groups/presentation/providers/groups_providers.dart';

/// Chats hub (spec Tab 3): one row per susu group, each opening the group
/// conversation. Last-message previews load lazily per row.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Chats')),
      body: groupsAsync.when(
        loading: () => const AppLoadingView(message: 'Loading conversations…'),
        error: (error, stackTrace) => AppErrorState(
          onRetry: () => ref.read(myGroupsProvider.notifier).refresh(),
        ),
        data: (groups) {
          if (groups.isEmpty) {
            return const AppEmptyState(
              title: 'No conversations yet',
              message: 'Join or create a susu group to start chatting.',
              icon: Icons.chat_bubble_outline,
            );
          }
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: <Widget>[
              Text(
                'Group conversations',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 8),
              ...groups.map(
                (SusuGroup group) => _ChatRow(group: group),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ChatRow extends ConsumerWidget {
  const _ChatRow({required this.group});

  final SusuGroup group;

  String _preview(GroupMessage? message) {
    if (message == null) return 'No messages yet';
    final raw = '${message.senderName}: ${message.body}';
    return raw.length > 48 ? '${raw.substring(0, 45)}…' : raw;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(groupMessagesProvider(group.id));
    final preview = switch (messagesAsync) {
      AsyncData<List<GroupMessage>>(:final value) => _preview(value.firstOrNull),
      _ => 'Loading…',
    };

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: const BorderSide(color: AppColors.outline),
        ),
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: theme.colorScheme.primaryContainer,
            child: Icon(
              Icons.groups,
              color: theme.colorScheme.primary,
            ),
          ),
          title: Text(group.name, style: theme.textTheme.emphasis),
          subtitle: Text(
            preview,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall,
          ),
          trailing: const Icon(Icons.chevron_right, size: 20),
          onTap: () => context.go(AppRoutes.groupDetails(group.id)),
        ),
      ),
    );
  }
}
