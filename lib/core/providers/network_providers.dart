import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../network/api_client.dart';
import '../network/api_config.dart';
import '../network/token_store.dart';
import 'app_providers.dart';

/// Compile-time API configuration (from `--dart-define`).
final apiConfigProvider = Provider<ApiConfig>(
  (ref) => ApiConfig.fromEnvironment(),
);

/// Token store backed by platform secure storage (spec §10, §27).
final tokenStoreProvider = Provider<TokenStore>(
  (ref) => SecureStorageTokenStore(ref.watch(secureStorageProvider)),
);

/// Hook fired when the session expires (refresh failure). Phase 3 overrides
/// this provider to sign the user out; default is a no-op so the network
/// layer stays feature-independent.
final sessionExpiredHandlerProvider = Provider<void Function()?>(
  (ref) => null,
);

/// Singleton API client with auth + logging interceptors.
final apiClientProvider = Provider<ApiClient>((ref) {
  return ApiClient(
    config: ref.watch(apiConfigProvider),
    tokenStore: ref.watch(tokenStoreProvider),
    onSessionExpired: ref.watch(sessionExpiredHandlerProvider),
  );
});
