import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/shared/utils/logger.dart';

/// Owns everything stored in the platform keychain / keystore.
class UserLocalDataSource {
  UserLocalDataSource({FlutterSecureStorage? secureStorage})
    : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const String authenticationEntityKey = 'authentication_entity_key';

  final FlutterSecureStorage _secureStorage;

  Future<void> saveAuthenticationEntity(AuthenticationEntity entity) {
    return _secureStorage.write(
      key: authenticationEntityKey,
      value: jsonEncode(entity.toJson()),
    );
  }

  Future<AuthenticationEntity?> getAppAuth() async {
    try {
      final raw = await _secureStorage.read(key: authenticationEntityKey);
      if (raw == null) return null;
      return AuthenticationEntity.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } on Object catch (e) {
      // A malformed or undecryptable blob must not brick the app on launch.
      logger.e('Failed to read stored session', error: e);
      await logout();
      return null;
    }
  }

  Future<AuthenticationEntity?> updateAppAuth({
    String? accessToken,
    String? refreshToken,
    String? userId,
  }) async {
    final current = await getAppAuth();
    if (current == null) return null;

    final updated = current.copyWith(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
    );
    await saveAuthenticationEntity(updated);
    return updated;
  }

  Future<bool> hasSession() async => (await getAppAuth())?.isValid ?? false;

  Future<void> logout() => _secureStorage.deleteAll();
}
