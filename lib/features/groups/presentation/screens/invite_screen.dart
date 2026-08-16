import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../domain/group_models.dart';
import '../providers/groups_providers.dart';

/// Invite Friends (design reference): pick a susu group, copy its invite
/// code and share it — the join-by-code flow (`/groups/join`) consumes the
/// code.
class InviteScreen extends ConsumerWidget {
  const InviteScreen({super.key});

  Future<void> _copy(BuildContext context, String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Invite code $code copied'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupsAsync = ref.watch(myGroupsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Invite Friends')),
      body: groupsAsync.when(
        loading: () => const AppLoadingView(message: 'Loading your groups…'),
        error: (error, stackTrace) => AppErrorState(
          onRetry: () => ref.read(myGroupsProvider.notifier).refresh(),
        ),
        data: (groups) {
          final active = groups.where((g) => g.isActive).toList();
          if (active.isEmpty) {
            return const AppEmptyState(
              title: 'No active susu groups',
              message: 'Create or join a group first, then invite friends.',
              icon: Icons.person_add_alt_1_outlined,
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              Text(
                'Share an invite code and friends can join by entering it in '
                'the app (Join Susu).',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              ...active.map(
                (SusuGroup group) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _InviteCard(group: group, onCopy: _copy),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _InviteCard extends ConsumerWidget {
  const _InviteCard({required this.group, required this.onCopy});

  final SusuGroup group;
  final Future<void> Function(BuildContext context, String code) onCopy;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final codeAsync = ref.watch(inviteCodeProvider(group.id));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.groups, color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(group.name, style: theme.textTheme.emphasis),
                    Text(
                      '${group.memberCount} members',
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          codeAsync.when(
            loading: () => const LinearProgressIndicator(),
            error: (error, stackTrace) => Text(
              'Could not load invite code',
              style: theme.textTheme.bodySmall,
            ),
            data: (code) => Row(
              children: <Widget>[
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      code,
                      style: theme.textTheme.emphasis.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.tonalIcon(
                  onPressed: () => onCopy(context, code),
                  icon: const Icon(Icons.copy, size: 18),
                  label: const Text('Copy'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
