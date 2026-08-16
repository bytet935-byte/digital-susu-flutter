import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../domain/group_models.dart';
import '../providers/groups_providers.dart';

/// Members tab (build spec §9, §16): member list with role badges, the
/// owner highlighted, plus add-member / role / remove actions for the
/// owner and moderators (permission-driven).
class GroupMembersTab extends ConsumerStatefulWidget {
  const GroupMembersTab({
    super.key,
    required this.groupId,
    required this.currentUserId,
  });

  final String groupId;
  final String currentUserId;

  @override
  ConsumerState<GroupMembersTab> createState() => _GroupMembersTabState();
}

class _GroupMembersTabState extends ConsumerState<GroupMembersTab> {
  final TextEditingController _identifierController = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _identifierController.dispose();
    super.dispose();
  }

  Future<void> _showAddDialog() async {
    _identifierController.clear();
    final identifier = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add member'),
        content: TextField(
          controller: _identifierController,
          autofocus: true,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            labelText: 'Phone number or email',
            hintText: 'e.g. 0559876543',
            border: OutlineInputBorder(),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(context).pop(_identifierController.text.trim()),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (identifier == null || identifier.isEmpty || !mounted) return;

    setState(() => _adding = true);
    final error = await ref
        .read(groupMembersProvider(widget.groupId).notifier)
        .addMember(
          groupId: widget.groupId,
          identifier: identifier,
          actorId: widget.currentUserId,
        );
    if (!mounted) return;
    setState(() => _adding = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? 'Member added'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _changeRole(
    GroupMember member,
    String role,
    String actionLabel,
  ) async {
    final error = await ref
        .read(groupMembersProvider(widget.groupId).notifier)
        .updateRole(
          groupId: widget.groupId,
          memberId: member.userId,
          role: role,
          actorId: widget.currentUserId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '$actionLabel: ${member.fullName}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _removeMember(GroupMember member) async {
    final error = await ref
        .read(groupMembersProvider(widget.groupId).notifier)
        .removeMember(
          groupId: widget.groupId,
          memberId: member.userId,
          actorId: widget.currentUserId,
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(error ?? '${member.fullName} removed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final membersAsync = ref.watch(groupMembersProvider(widget.groupId));

    return membersAsync.when(
      loading: () => const AppLoadingView(),
      error: (error, stackTrace) => AppErrorState(
        onRetry: () => ref.invalidate(groupMembersProvider(widget.groupId)),
      ),
      data: (members) {
        final canManage = members.any(
          (GroupMember m) =>
              m.userId == widget.currentUserId &&
              (m.role == GroupRoles.owner ||
                  m.role == GroupRoles.admin ||
                  m.role == GroupRoles.moderator),
        );
        if (members.isEmpty) {
          return const AppEmptyState(
            title: 'No members yet',
            message: 'Invite members to start saving together.',
            icon: Icons.people_outline,
          );
        }
        return Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
              child: Row(
                children: <Widget>[
                  Text('Members (${members.length})',
                      style: theme.textTheme.titleSmall),
                  const Spacer(),
                  if (canManage)
                    TextButton.icon(
                      onPressed: _adding ? null : _showAddDialog,
                      icon: const Icon(Icons.person_add_alt_1, size: 18),
                      label: const Text('Add Member'),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: members.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final member = members[index];
                  final isMe = member.userId == widget.currentUserId;
                  final canEdit = canManage &&
                      !isMe &&
                      member.role != GroupRoles.owner;
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
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
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
                        if (canEdit)
                          PopupMenuButton<String>(
                            tooltip: 'Manage ${member.fullName}',
                            onSelected: (String action) {
                              switch (action) {
                                case 'treasurer':
                                  _changeRole(
                                      member, GroupRoles.treasurer,
                                      'Made treasurer');
                                case 'moderator':
                                  _changeRole(
                                      member, GroupRoles.moderator,
                                      'Made moderator');
                                case 'member':
                                  _changeRole(
                                      member, GroupRoles.member,
                                      'Made member');
                                case 'remove':
                                  _removeMember(member);
                              }
                            },
                            itemBuilder: (context) => <PopupMenuEntry<String>>[
                              const PopupMenuItem<String>(
                                value: 'treasurer',
                                child: Text('Make treasurer'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'moderator',
                                child: Text('Make moderator'),
                              ),
                              const PopupMenuItem<String>(
                                value: 'member',
                                child: Text('Make member'),
                              ),
                              const PopupMenuDivider(),
                              const PopupMenuItem<String>(
                                value: 'remove',
                                child: Text('Remove',
                                    style: TextStyle(color: AppColors.danger)),
                              ),
                            ],
                          ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}
