import '../config/environment.dart';

/// Picks the mock or API implementation of a repository based on the
/// compile-time `USE_MOCK_DATA` flag (spec §11).
///
/// Mock mode is the default so the app runs out of the box in development.
T selectRepository<T>({required T mock, required T api}) =>
    AppEnvironment.useMockData ? mock : api;
