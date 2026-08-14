import 'package:flutter_test/flutter_test.dart';
import 'package:digital_susu/core/config/environment.dart';
import 'package:digital_susu/core/network/repository_selector.dart';

void main() {
  group('RepositorySelector — mock fallback (spec §11)', () {
    test('defaults to the mock implementation (USE_MOCK_DATA=true)', () {
      expect(AppEnvironment.useMockData, isTrue,
          reason: 'dev default must be mock so the app runs without a backend');
    });

    test('selects the mock implementation in mock mode', () {
      final selected = selectRepository<String>(mock: 'mock-repo', api: 'api-repo');
      expect(selected, 'mock-repo');
    });

    test('selector type is uniform for both branches', () {
      // Compile-time guarantee: both branches must satisfy the same type.
      final mock = MockGroupsRepository();
      final api = ApiGroupsRepository();
      final selected = selectRepository<GroupsRepository>(
        mock: mock,
        api: api,
      );
      expect(selected, isA<MockGroupsRepository>());
      expect(selected.fetch(), 'mock groups');
    });
  });
}

/// Minimal shape of a feature repository (real ones arrive from Phase 3).
abstract class GroupsRepository {
  String fetch();
}

class MockGroupsRepository implements GroupsRepository {
  @override
  String fetch() => 'mock groups';
}

class ApiGroupsRepository implements GroupsRepository {
  @override
  String fetch() => 'api groups';
}
