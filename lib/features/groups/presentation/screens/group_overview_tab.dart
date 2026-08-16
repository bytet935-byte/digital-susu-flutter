import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/status_badge.dart';
import '../../../contributions/presentation/widgets/contribute_sheet.dart';
import '../../domain/group_models.dart';
import '../providers/groups_providers.dart';
/// Overview tab (build spec §9): description, status, pot, members, next
/// payout, type, and the Contribute Now entry point (Phase 6).
class GroupOverviewTab extends ConsumerWidget {
  const GroupOverviewTab({super.key, required this.group});

  final SusuGroup group;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        if (group.myTarget != null && group.myTarget!.amountMinor > 0) ...<Widget>[
          const SizedBox(height: 16),
          _ContributionProgress(group: group),
        ],
        if (group.type == GroupTypes.rotationalSusu) ...<Widget>[
          const SizedBox(height: 16),
          _PayoutScheduleCard(groupId: group.id),
        ],
        const SizedBox(height: 20),
        // Contribution progress is driven by the contribution schedule
        // (Phase 7); the sheet below is the Phase 6 entry point.
        FilledButton.icon(
          onPressed: () async {
            final contributed =
                await showContributeSheet(context, group: group);
            if (contributed == true && context.mounted) {
              // Refresh the pot shown in the overview/stats.
              ref.invalidate(groupDetailsProvider(group.id));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Contribution recorded 🎉'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
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

/// "My Contribution" progress bar (design reference screen 8).
class _ContributionProgress extends StatelessWidget {
  const _ContributionProgress({required this.group});

  final SusuGroup group;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final target = group.myTarget!;
    final progress =
        target.amountMinor <= 0 ? 0.0 : group.myContribution.amountMinor / target.amountMinor;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('My Contribution', style: theme.textTheme.titleSmall),
                Text(
                  '${group.myContribution.format()} of ${target.format()}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 8,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              '${(progress.clamp(0.0, 1.0) * 100).round()}% of target',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

/// Rotational susu payout schedule (Phase 7): cycle progress, next payout
/// and the upcoming rotation. Hidden when no schedule is available.
class _PayoutScheduleCard extends ConsumerWidget {
  const _PayoutScheduleCard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheduleAsync = ref.watch(payoutScheduleProvider(groupId));
    return scheduleAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (schedule) => _PayoutCard(schedule: schedule),
    );
  }
}

class _PayoutCard extends StatelessWidget {
  const _PayoutCard({required this.schedule});

  final SusuSchedule schedule;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final next = schedule.upcomingPayouts.firstOrNull;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Payout Schedule', style: theme.textTheme.titleSmall),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    'Cycle ${schedule.cycleNumber} of ${schedule.totalCycles}',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: schedule.progress,
                minHeight: 6,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                const Icon(Icons.payments_outlined,
                    size: 18, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  'Next payout: ${schedule.payoutAmount.format()}',
                  style: theme.textTheme.emphasis,
                ),
              ],
            ),
            if (next != null) ...<Widget>[
              const SizedBox(height: 4),
              Padding(
                padding: const EdgeInsets.only(left: 26),
                child: Text(
                  '${next.memberName} · '
                  '${DateFormatter.formatDate(next.date)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
            const Divider(height: 24),
            Text('Upcoming payouts', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final PayoutTurn turn in schedule.upcomingPayouts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Text(
                        turn.memberName,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      DateFormatter.formatDate(turn.date),
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      turn.amount.format(),
                      style: theme.textTheme.emphasis,
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 6),
            Text(
              '${schedule.contributionPerCycle.format()} per cycle · '
              '${schedule.frequencyLabel}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
