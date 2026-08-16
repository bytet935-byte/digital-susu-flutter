import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/models/money.dart';
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
        if (group.type == GroupTypes.savingsGoal) ...<Widget>[
          const SizedBox(height: 16),
          _SavingsGoalCard(groupId: group.id, pot: group.pot),
        ],
        if (group.type == GroupTypes.jointBusiness) ...<Widget>[
          const SizedBox(height: 16),
          _BusinessReportCard(groupId: group.id),
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

/// Savings-goal group progress (Phase 7): goal pot, target date, milestone
/// ladder. Hidden when no goal is available.
class _SavingsGoalCard extends ConsumerWidget {
  const _SavingsGoalCard({required this.groupId, required this.pot});

  final String groupId;
  final Money pot;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final goalAsync = ref.watch(savingsGoalProvider(groupId));
    return goalAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (goal) => _GoalCard(groupId: groupId, pot: pot, goal: goal),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.groupId, required this.pot, required this.goal});

  final String groupId;
  final Money pot;
  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        goal.targetAmount.amountMinor <= 0
            ? 0.0
            : (pot.amountMinor / goal.targetAmount.amountMinor).clamp(0.0, 1.0);
    final targetDate = goal.targetDate;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Goal Progress', style: theme.textTheme.titleSmall),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${goal.targetAmount.format()} goal',
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
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.background,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  '${pot.format()} of ${goal.targetAmount.format()}',
                  style: theme.textTheme.emphasis,
                ),
                if (targetDate != null)
                  Text(
                    'by ${DateFormatter.formatDate(targetDate)}',
                    style: theme.textTheme.bodySmall,
                  ),
              ],
            ),
            const Divider(height: 24),
            Text('Milestones', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final GoalMilestone milestone in goal.milestones)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      pot.amountMinor >= milestone.amount.amountMinor
                          ? Icons.check_circle
                          : Icons.radio_button_unchecked,
                      size: 18,
                      color: pot.amountMinor >= milestone.amount.amountMinor
                          ? AppColors.success
                          : AppColors.onSurfaceVariant,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      milestone.label,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Text(
                      milestone.amount.format(),
                      style: theme.textTheme.emphasis,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Joint-business period report (Phase 7): capital, revenue / expenses /
/// profit and the latest activity. Hidden when no report is available.
class _BusinessReportCard extends ConsumerWidget {
  const _BusinessReportCard({required this.groupId});

  final String groupId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync = ref.watch(businessReportProvider(groupId));
    return reportAsync.when(
      loading: () => const SizedBox(height: 80),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (report) => _ReportCard(report: report),
    );
  }
}

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report});

  final BusinessReport report;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text('Business Report', style: theme.textTheme.titleSmall),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${report.capital.format()} capital',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: <Widget>[
                Expanded(
                  child: _Stat(
                    label: 'Revenue',
                    value: report.revenue.format(),
                    color: AppColors.moneyPositive,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Expenses',
                    value: report.expenses.format(),
                    color: AppColors.moneyNegative,
                  ),
                ),
                Expanded(
                  child: _Stat(
                    label: 'Profit',
                    value: report.profit.format(),
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Text('Recent activity', style: theme.textTheme.titleSmall),
            const SizedBox(height: 4),
            for (final BusinessEntry entry in report.recentActivity.take(4))
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: <Widget>[
                    Icon(
                      entry.isCredit
                          ? Icons.trending_up
                          : Icons.trending_down,
                      size: 16,
                      color: entry.isCredit
                          ? AppColors.moneyPositive
                          : AppColors.moneyNegative,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        entry.description,
                        style: theme.textTheme.bodyMedium,
                      ),
                    ),
                    Text(
                      entry.amount.format(),
                      style: theme.textTheme.emphasis.copyWith(
                        color: entry.isCredit
                            ? AppColors.moneyPositive
                            : AppColors.moneyNegative,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(label, style: theme.textTheme.bodySmall),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.emphasis.copyWith(color: color),
        ),
      ],
    );
  }
}
