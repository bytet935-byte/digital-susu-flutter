import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../storage/storage_service.dart';

/// App-level providers (Phase 1). Feature providers live next to their
/// features; repositories/services are added from Phase 2 onward.
///
/// Storage providers are overridable in tests with in-memory fakes.
final secureStorageProvider = Provider<SecureStorageService>(
  (ref) => FlutterSecureStorageService(),
);

final localStorageProvider = Provider<LocalStorageService>(
  (ref) => SharedPreferencesLocalStorageService(),
);
