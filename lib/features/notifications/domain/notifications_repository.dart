import '../../../../core/utils/result.dart';
import 'app_notification.dart';

/// Notifications contract (spec §21).
abstract interface class NotificationsRepository {
  Future<Result<List<AppNotification>>> getNotifications();

  Future<Result<int>> getUnreadCount();

  Future<Result<void>> markRead(String notificationId);

  Future<Result<void>> markAllRead();
}
