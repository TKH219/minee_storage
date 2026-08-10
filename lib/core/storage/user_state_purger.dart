import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme_mode_provider.dart';

/// Wipes everything belonging to the signed-in user.
///
/// Deny-by-default: secure storage is emptied wholesale and every preference
/// is removed unless it is on [keptPreferenceKeys], so a cache added later is
/// purged without anyone remembering to update this class. That is what stops
/// one account's data from surfacing under the next account on a shared device.
class UserStatePurger {
  UserStatePurger({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
    Future<SharedPreferences> Function() preferences = SharedPreferences.getInstance,
  }) : _secureStorage = secureStorage,
       _preferences = preferences;

  /// Device settings that outlive whoever is signed in.
  static const Set<String> keptPreferenceKeys = {ThemeModeNotifier.storageKey};

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _preferences;

  /// Signing out triggers this rather than being part of it: the auth state
  /// stream fires once GoTrue has already dropped the session, which is also
  /// what covers a background token refresh failing with nothing in flight.
  Future<void> purge() async {
    await _secureStorage.deleteAll();

    final prefs = await _preferences();
    for (final key in prefs.getKeys().toList()) {
      if (!keptPreferenceKeys.contains(key)) {
        await prefs.remove(key);
      }
    }
  }
}
