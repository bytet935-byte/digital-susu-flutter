import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/routing/app_routes.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../../../authentication/presentation/providers/auth_providers.dart';
import '../domain/dashboard_models.dart';
import '../providers/dashboard_providers.dart';
import '../widgets/dashboard_widgets.dart';

/// Dashboard per design reference (spec §13): greeting, total-balance hero
/// card, quick actions, active susu with progress, recent transactions.
/// Loading / error / retry states per spec §32.
class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final summaryAsync = ref.watch(dashboardSummaryProvider);
    final auth = ref.watch(authStateProvider);
    final user = switch (auth) {
      AuthAuthenticated(:final session) => session.user,
      _ => null,
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hello, ${user?.fullName.split(' ').first ?? 'there'} 👋',
        ),
        actions: <Widget>[
          // Notifications bell with unread badge.
          IconButton(
            onPressed: () => context.go(AppRoutes.notifications),
            icon: _NotificationBell(
              unread: summaryAsync.valueOrNull?.unreadNotifications ?? 0,
            ),
          ),
        ],
      ),
      body: summaryAsync.when(
        loading: () => const AppLoadingView(message: 'Loading your savings…'),
        error: (error, stackTrace) => AppErrorState(
          message: error is AppException
              ? error.message
              : 'Could not load your dashboard',
          onRetry: () =>
              ref.read(dashboardSummaryProvider.notifier).refresh(),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () => ref.read(dashboardSummaryProvider.notifier).refresh(),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: <Widget>[
              BalanceCard(balance: summary.totalBalance),
              const SizedBox(height: 24),
              const QuickActions(),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text('Active Susu', style: theme.textTheme.titleMedium),
                  TextButton(
                    onPressed: () => context.go(AppRoutes.groups),
                    child: const Text('View all'),
                  ),
                ],
              ),
              if (summary.activeGroups.isEmpty)
                const AppEmptyState(
                  title: 'No active susu groups',
                  message: 'Create or join a group to start saving together.',
                  icon: Icons.groups_outlined,
                )
              else
                ...summary.activeGroups.map(
                  (DashboardGroup group) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: SusuCard(
                      group: group,
                      onTap: () =>
                          context.go(AppRoutes.groupDetails(group.id)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Text('Recent Transactions', style: theme.textTheme.titleMedium),
              const SizedBox(height: 8),
              if (summary.recentTransactions.isEmpty)
                const AppEmptyState(
                  title: 'No transactions yet',
                  icon: Icons.receipt_long_outlined,
                )
              else
                ...summary.recentTransactions
                    .take(5)
                    .map((t) => TransactionTile(transaction: t)),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationBell extends StatelessWidget {
  const _NotificationBell({required this.unread});

  final int unread;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Badge(
      isLabelVisible: unread > 0,
      label: Text('$unread'),
      child: Icon(
        Icons.notifications_outlined,
        color: theme.colorScheme.onSurface,
      ),
    );
  }
}
