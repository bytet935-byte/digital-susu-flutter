import '../../../core/utils/result.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

/// Deterministic mock notifications matching the design reference
/// (spec §21): New Contribution, Upcoming Payout, Payment Successful,
/// New Member Added.
class MockNotificationsRepository implements NotificationsRepository {
  final List<AppNotification> _items = <AppNotification>[
    AppNotification(
      id: 'ntf_1',
      title: 'New Contribution',
      body: 'Ama Serwaa contributed GH₵ 50.00 to Weekend Susu.',
      category: 'contribution_reminder',
      createdAt: DateTime(2026, 8, 14, 9, 35),
      read: false,
    ),
    AppNotification(
      id: 'ntf_2',
      title: 'Upcoming Payout',
      body: 'Your Weekend Susu payout is due on 25 August 2026.',
      category: 'payout',
      createdAt: DateTime(2026, 8, 14, 8, 0),
      read: false,
    ),
    AppNotification(
      id: 'ntf_3',
      title: 'Payment Successful',
      body: 'Your top-up of GH₵ 200.00 was successful.',
      category: 'payment_confirmation',
      createdAt: DateTime(2026, 8, 13, 18, 10),
      read: false,
    ),
    AppNotification(
      id: 'ntf_4',
      title: 'New Member Added',
      body: 'Kojo Antwi joined Project Susu.',
      category: 'group_announcement',
      createdAt: DateTime(2026, 8, 12, 14, 25),
      read: true,
    ),
  ];

  @override
  Future<Result<List<AppNotification>>> getNotifications() async =>
      Success<List<AppNotification>>(
        _items.toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt)), // newest first
      );

  @override
  Future<Result<int>> getUnreadCount() async =>
      Success<int>(_items.where((n) => !n.read).length);

  @override
  Future<Result<void>> markRead(String notificationId) async {
    final index = _items.indexWhere((n) => n.id == notificationId);
    if (index >= 0) _items[index] = _items[index].copyWith(read: true);
    return const Success<void>(null);
  }

  @override
  Future<Result<void>> markAllRead() async {
    for (var i = 0; i < _items.length; i++) {
      _items[i] = _items[i].copyWith(read: true);
    }
    return const Success<void>(null);
  }
}
