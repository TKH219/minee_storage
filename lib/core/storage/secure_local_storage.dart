import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Keeps the GoTrue session in the keychain/keystore. The package default is
/// SharedPreferences, which stores a long-lived refresh token in plaintext.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? secureStorage})
    : _storage = secureStorage ?? const FlutterSecureStorage();

  static const String sessionKey = 'supabase_session';

  final FlutterSecureStorage _storage;

  @override
  Future<void> initialize() async {}

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
