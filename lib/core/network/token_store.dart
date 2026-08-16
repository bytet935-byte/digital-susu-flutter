import '../config/app_config.dart';
import '../storage/storage_service.dart';

/// Persistence for access/refresh tokens (spec §10, §27).
///
/// Production uses platform secure storage via [SecureStorageTokenStore];
/// tests use [InMemoryTokenStore].
abstract interface class TokenStore {
  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  });

  Future<void> clear();
}

/// Production token store backed by the platform secure storage service
/// (Keychain / Keystore / encrypted storage).
class SecureStorageTokenStore implements TokenStore {
  SecureStorageTokenStore(this._secure);

  final SecureStorageService _secure;

  @override
  Future<String?> readAccessToken() =>
      _secure.read(AppConfig.secureKeyAccessToken);

  @override
  Future<String?> readRefreshToken() =>
      _secure.read(AppConfig.secureKeyRefreshToken);

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _secure.write(AppConfig.secureKeyAccessToken, accessToken);
    await _secure.write(AppConfig.secureKeyRefreshToken, refreshToken);
  }

  @override
  Future<void> clear() async {
    await _secure.delete(AppConfig.secureKeyAccessToken);
    await _secure.delete(AppConfig.secureKeyRefreshToken);
  }
}

/// In-memory token store for tests and mock-mode (spec §11).
class InMemoryTokenStore implements TokenStore {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
