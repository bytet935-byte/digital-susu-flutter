import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/features/notifications/data/mock_notifications_repository.dart';

void main() {
  late MockNotificationsRepository repo;

  setUp(() {
    repo = MockNotificationsRepository();
  });

  group('MockNotificationsRepository (spec §21)', () {
    test('returns design-reference notifications newest first', () async {
      final items = (await repo.getNotifications()).valueOrNull!;
      expect(items, hasLength(4));
      expect(items.first.title, 'New Contribution');
      expect(items.last.title, 'New Member Added');
    });

    test('unread count matches the design (3 unread)', () async {
      final unread = (await repo.getUnreadCount()).valueOrNull;
      expect(unread, 3);
    });

    test('markRead flips a single notification', () async {
      await repo.markRead('ntf_1');
      final items = (await repo.getNotifications()).valueOrNull!;
      expect(items.firstWhere((n) => n.id == 'ntf_1').read, isTrue);
      expect((await repo.getUnreadCount()).valueOrNull, 2);
    });

    test('markAllRead clears the unread count', () async {
      await repo.markAllRead();
      expect((await repo.getUnreadCount()).valueOrNull, 0);
    });
  });
}
