import '../config/environment.dart';

/// Mock/API repository selection seam (spec §11).
///
/// Feature repositories use this helper so the UI never changes when
/// switching `USE_MOCK_DATA`:
///
/// ```dart
/// final groupsRepositoryProvider = Provider<GroupsRepository>((ref) =>
///     selectRepository(
///       mock: MockGroupsRepository(),
///       api: ApiGroupsRepository(ref.watch(apiClientProvider)),
///     ));
/// ```
T selectRepository<T>({required T mock, required T api}) =>
    AppEnvironment.useMockData ? mock : api;
