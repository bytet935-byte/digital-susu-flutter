import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/repository_selector.dart';
import '../../../../core/providers/network_providers.dart';
import '../../../../core/utils/result.dart';
import '../data/api_notifications_repository.dart';
import '../data/mock_notifications_repository.dart';
import '../domain/app_notification.dart';
import '../domain/notifications_repository.dart';

/// Switches mock/API via USE_MOCK_DATA (spec §11).
final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => selectRepository<NotificationsRepository>(
    mock: MockNotificationsRepository(),
    api: ApiNotificationsRepository(ref.watch(apiClientProvider)),
  ),
);

/// Loads the notification list; supports mark-read operations.
final notificationsProvider =
    AsyncNotifierProvider<NotificationsController, List<AppNotification>>(
  NotificationsController.new,
);

class NotificationsController
    extends AsyncNotifier<List<AppNotification>> {
  NotificationsRepository get _repo => ref.read(notificationsRepositoryProvider);

  @override
  Future<List<AppNotification>> build() => _fetch();

  Future<List<AppNotification>> _fetch() async {
    final result = await _repo.getNotifications();
    return switch (result) {
      Success<List<AppNotification>>(:final value) => value,
      Failure<List<AppNotification>>(:final error) => throw error,
    };
  }

  /// Unread count derived from the loaded list (kept in sync locally).
  int unreadCount(List<AppNotification> items) =>
      items.where((n) => !n.read).length;

  Future<void> markRead(String notificationId) async {
    final result = await _repo.markRead(notificationId);
    final current = state.valueOrNull;
    if (result is Failure<void> || current == null) return;
    state = AsyncData(
      current
          .map((n) => n.id == notificationId ? n.copyWith(read: true) : n)
          .toList(),
    );
  }

  Future<void> markAllRead() async {
    final result = await _repo.markAllRead();
    final current = state.valueOrNull;
    if (result is Failure<void> || current == null) return;
    state = AsyncData(current.map((n) => n.copyWith(read: true)).toList());
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(_fetch);
  }
}
