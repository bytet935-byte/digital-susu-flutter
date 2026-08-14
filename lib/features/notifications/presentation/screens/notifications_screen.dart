import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/app_loading.dart';
import '../../../../shared/widgets/app_states.dart';
import '../domain/app_notification.dart';
import '../providers/notifications_providers.dart';

/// Notifications screen per design reference (spec §21): list of activity
/// with read/unread states, mark-all-read action.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final notificationsAsync = ref.watch(notificationsProvider);
    final controller = ref.read(notificationsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: <Widget>[
          TextButton(
            onPressed: () => controller.markAllRead(),
            child: const Text('Mark all read'),
          ),
        ],
      ),
      body: notificationsAsync.when(
        loading: () => const AppLoadingView(),
        error: (error, stackTrace) => AppErrorState(
          onRetry: () => controller.refresh(),
        ),
        data: (items) {
          if (items.isEmpty) {
            return const AppEmptyState(
              title: 'No notifications yet',
              message:
                  'Contribution reminders, payouts and announcements will '
                  'appear here.',
              icon: Icons.notifications_none_outlined,
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final notification = items[index];
              return _NotificationTile(
                notification: notification,
                onTap: () => controller.markRead(notification.id),
              );
            },
          );
        },
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({required this.notification, required this.onTap});

  final AppNotification notification;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unread = !notification.read;
    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: unread
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest,
        child: Icon(
          _iconFor(notification.category),
          size: 18,
          color: unread ? theme.colorScheme.primary : theme.colorScheme.outline,
        ),
      ),
      title: Text(
        notification.title,
        style: theme.textTheme.bodyMedium?.copyWith(
          fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
        ),
      ),
      subtitle: Text(
        '${notification.body}\n${DateFormatter.formatDateTime(notification.createdAt)}',
        style: theme.textTheme.caption,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: unread
          ? Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }

  IconData _iconFor(String category) => switch (category) {
        'contribution_reminder' || 'missed_contribution' =>
          Icons.savings_outlined,
        'payment_confirmation' || 'transaction_alert' =>
          Icons.check_circle_outline,
        'payout' => Icons.payments_outlined,
        'group_announcement' || 'new_member' => Icons.campaign_outlined,
        'proposal' || 'voting_reminder' => Icons.how_to_vote_outlined,
        'security_alert' => Icons.security_outlined,
        _ => Icons.notifications_outlined,
      };
}
