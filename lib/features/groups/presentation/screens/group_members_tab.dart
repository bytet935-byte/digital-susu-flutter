import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../domain/group_models.dart';
import '../providers/groups_providers.dart';

/// Members tab (build spec §9): member list with role badges and the owner
/// highlighted. Add/remove member actions arrive with permission wiring
/// (Phase 5 follow-up / Phase 8).
class GroupMembersTab extends ConsumerWidget {
  const GroupMembersTab({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  final String groupId;
  final String currentUserId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(groupMembersProvider(groupId));

    return membersAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorState(
        onRetry: () => ref.invalidate(groupMembersProvider(groupId)),
      ),
      data: (members) {
        if (members.isEmpty) {
          return const AppEmptyState(
            title: 'No members yet',
            message: 'Invite members to start saving together.',
            icon: Icons.people_outline,
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: members.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, index) {
            final member = members[index];
            final isMe = member.userId == currentUserId;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  member.fullName.isNotEmpty
                      ? member.fullName[0].toUpperCase()
                      : '?',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              title: Text(
                isMe ? '${member.fullName} (You)' : member.fullName,
                style: theme.textTheme.bodyMedium,
              ),
              subtitle: Text(
                PhoneFormatter.formatDisplay(member.phone),
                style: theme.textTheme.caption,
              ),
              trailing: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: member.role == GroupRoles.owner
                      ? AppColors.secondaryContainer
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  GroupRoles.label(member.role),
                  style: TextStyle(
                    fontSize: 11,
                    color: member.role == GroupRoles.owner
                        ? AppColors.onSecondary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
