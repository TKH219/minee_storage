import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme_mode_provider.dart';
import 'package:mine_storage/shared/utils/logger.dart';

/// Wipes everything belonging to the signed-in user.
///
/// Deny-by-default: secure storage is emptied wholesale and every preference
/// is removed unless it is on [keptPreferenceKeys], so a cache added later is
/// purged without anyone remembering to update this class. That is what stops
/// one account's data from surfacing under the next account on a shared device.
class UserStatePurger {
  UserStatePurger({
    required Future<void> Function() signOut,
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
    Future<SharedPreferences> Function() preferences = SharedPreferences.getInstance,
  }) : _signOut = signOut,
       _secureStorage = secureStorage,
       _preferences = preferences;

  /// Device settings that outlive whoever is signed in.
  static const Set<String> keptPreferenceKeys = {ThemeModeNotifier.storageKey};

  final Future<void> Function() _signOut;
  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _preferences;

  Future<void> purge() async {
    // A dead session is exactly when sign-out is most likely to fail, and
    // local state must be cleared either way.
    try {
      await _signOut();
    } on Object catch (e) {
      logger.e('Sign-out during purge failed', error: e);
    }

    await _secureStorage.deleteAll();

    final prefs = await _preferences();
    for (final key in prefs.getKeys().toList()) {
      if (!keptPreferenceKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
  }
}
