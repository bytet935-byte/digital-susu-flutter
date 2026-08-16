import '../../../core/errors/app_exception.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/utils/result.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

/// Real-backend notifications repository.
class ApiNotificationsRepository implements NotificationsRepository {
  ApiNotificationsRepository(this._client);

  final ApiClient _client;

  @override
  Future<Result<List<AppNotification>>> getNotifications() async {
    try {
      // Server returns { notifications: [...], unread_count: N }.
      final data = await _client.getMap(ApiEndpoints.notifications);
      final items = data['notifications'];
      if (items is! List<dynamic>) throw const MalformedResponseException();
      return Success<List<AppNotification>>(items
          .whereType<Map<String, dynamic>>()
          .map(AppNotification.fromJson)
          .toList());
    } on AppException catch (error) {
      return Failure<List<AppNotification>>(error);
    }
  }

  @override
  Future<Result<int>> getUnreadCount() async {
    try {
      final data = await _client.getMap(ApiEndpoints.notifications);
      return Success<int>(data['unread_count'] as int? ?? 0);
    } on AppException catch (error) {
      return Failure<int>(error);
    }
  }

  @override
  Future<Result<void>> markRead(String notificationId) async {
    try {
      await _client.postMap(ApiEndpoints.notification(notificationId));
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    }
  }

  @override
  Future<Result<void>> markAllRead() async {
    try {
      await _client.postMap(ApiEndpoints.notificationsReadAll);
      return const Success<void>(null);
    } on AppException catch (error) {
      return Failure<void>(error);
    }
  }
}
