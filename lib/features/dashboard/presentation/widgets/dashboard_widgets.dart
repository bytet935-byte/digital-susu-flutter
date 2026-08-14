import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/routing/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/money.dart';
import '../domain/dashboard_models.dart';

/// Navy hero card with the personal balance (design reference: Dashboard).
class BalanceCard extends StatelessWidget {
  const BalanceCard({super.key, required this.balance});

  final Money balance;

  @override
  Widget build(BuildContext context) {
    final formatted = balance.format();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: <Color>[AppColors.navy, AppColors.primary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            formatted,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppConfig.currencyCode,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.7),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

/// Quick actions row: My Susu, Payments, Invite, History (design reference).
class QuickActions extends StatelessWidget {
  const QuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: <Widget>[
        _QuickAction(
          icon: Icons.groups_outlined,
          label: 'My Susu',
          onTap: () => context.go(AppRoutes.groups),
        ),
        _QuickAction(
          icon: Icons.payments_outlined,
          label: 'Payments',
          onTap: () => context.go(AppRoutes.payments),
        ),
        _QuickAction(
          icon: Icons.person_add_alt_1_outlined,
          label: 'Invite',
          onTap: () {},
        ),
        _QuickAction(
          icon: Icons.history_outlined,
          label: 'History',
          onTap: () => context.go(AppRoutes.transactions),
        ),
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: theme.colorScheme.primary),
            ),
            const SizedBox(height: 6),
            Text(label, style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

/// Active susu card with progress (design reference: Weekend Susu).
class SusuCard extends StatelessWidget {
  const SusuCard({super.key, required this.group, this.onTap});

  final DashboardGroup group;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(group.name, style: theme.textTheme.titleMedium),
                  Text(group.pot.format(), style: theme.textTheme.emphasis),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${group.memberCount} members · '
                'Next payout ${group.nextPayout == null ? '—' : DateFormatter.formatDate(group.nextPayout!)}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.progress,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'My contribution ${group.myContribution.format()} of ${group.myTarget.format()}',
                style: theme.textTheme.caption,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Single transaction row: green credits / red debits (design reference).
class TransactionTile extends StatelessWidget {
  const TransactionTile({super.key, required this.transaction});

  final DashboardTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final amountColor = transaction.isCredit
        ? AppColors.moneyPositive
        : AppColors.moneyNegative;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          transaction.isCredit ? Icons.arrow_downward : Icons.arrow_upward,
          size: 18,
          color: amountColor,
        ),
      ),
      title: Text(transaction.description, style: theme.textTheme.bodyMedium),
      subtitle: Text(
        DateFormatter.formatDateTime(transaction.timestamp),
        style: theme.textTheme.caption,
      ),
      trailing: Text(
        transaction.amount.format(),
        style: theme.textTheme.emphasis.copyWith(color: amountColor),
      ),
    );
  }
}
