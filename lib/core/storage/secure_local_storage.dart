import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/core/storage/fresh_install_guard.dart';

/// Keeps the GoTrue session in the keychain/keystore. The package default is
/// SharedPreferences, which stores a long-lived refresh token in plaintext.
class SecureLocalStorage extends LocalStorage {
  factory SecureLocalStorage({
    FlutterSecureStorage? secureStorage,
    FreshInstallGuard? freshInstallGuard,
  }) => SecureLocalStorage._(
    secureStorage ?? const FlutterSecureStorage(),
    freshInstallGuard,
  );

  SecureLocalStorage._(FlutterSecureStorage storage, FreshInstallGuard? guard)
    : _storage = storage,
      _freshInstallGuard =
          guard ?? FreshInstallGuard(secureStorage: storage);

  static const String sessionKey = 'supabase_session';

  final FlutterSecureStorage _storage;
  final FreshInstallGuard _freshInstallGuard;

  /// GoTrue awaits this immediately before it reads the persisted session, so
  /// it is the one point where a stale install's credentials can be dropped
  /// without any caller having to remember the ordering.
  @override
  Future<void> initialize() => _freshInstallGuard.clearCredentialsIfReinstalled();

  @override
  Future<String?> accessToken() => _storage.read(key: sessionKey);

  @override
  Future<bool> hasAccessToken() => _storage.containsKey(key: sessionKey);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: sessionKey, value: persistSessionString);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: sessionKey);
}
