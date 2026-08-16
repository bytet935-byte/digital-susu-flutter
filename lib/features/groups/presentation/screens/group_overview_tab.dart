import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../domain/group_models.dart';
/// Overview tab (build spec §9): description, status, pot, members, next
/// payout, type. Contribution flow arrives with Phase 6.
class GroupOverviewTab extends StatelessWidget {
  const GroupOverviewTab({super.key, required this.group});

  final SusuGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        if (group.description.isNotEmpty) ...<Widget>[
          Text(group.description, style: theme.textTheme.bodyMedium),
          const SizedBox(height: 16),
        ],
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: <Widget>[
                _StatRow(label: 'Status', child: StatusBadge(status: group.status)),
                _StatRow(label: 'Type', value: GroupTypes.label(group.type)),
                _StatRow(label: 'Total Pot', value: group.pot.format(), emphasized: true),
                _StatRow(
                  label: 'Members',
                  value: '${group.memberCount} of ${group.totalMembers}',
                ),
                _StatRow(
                  label: 'Next Payout',
                  value: group.nextPayout == null
                      ? '—'
                      : DateFormatter.formatDate(group.nextPayout!),
                ),
                _StatRow(label: 'Currency', value: group.currency),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Contribution progress is driven by the contribution schedule
        // (Phase 7); the button below is the Phase 6 entry point.
        FilledButton.icon(
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Contributions arrive in Phase 6')),
            );
          },
          icon: const Icon(Icons.savings_outlined),
          label: const Text('Contribute Now'),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({
    required this.label,
    this.value,
    this.child,
    this.emphasized = false,
  });

  final String label;
  final String? value;
  final Widget? child;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: theme.textTheme.bodySmall),
          child ??
              Text(
                value ?? '—',
                style: emphasized
                    ? theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.primary,
                      )
                    : theme.textTheme.emphasis,
              ),
        ],
      ),
    );
  }
}
