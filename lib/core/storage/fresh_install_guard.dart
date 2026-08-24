import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Drops credentials that a previous install left behind on the device.
///
/// The iOS keychain outlives the app it belongs to, so after a reinstall the
/// stored GoTrue session is still there and signs the old account straight back
/// in. Preferences are removed with the app, which makes a missing
/// [installMarkerKey] the signal that secure storage predates this install.
class FreshInstallGuard {
  FreshInstallGuard({
    FlutterSecureStorage secureStorage = const FlutterSecureStorage(),
    Future<SharedPreferences> Function() preferences = SharedPreferences.getInstance,
  }) : _secureStorage = secureStorage,
       _preferences = preferences;

  static const String installMarkerKey = 'install_marker';

  final FlutterSecureStorage _secureStorage;
  final Future<SharedPreferences> Function() _preferences;

  /// Must run before Supabase is initialized, since initializing reads the
  /// persisted session and restores it.
  Future<void> clearCredentialsIfReinstalled() async {
    final prefs = await _preferences();
    if (prefs.getBool(installMarkerKey) ?? false) return;

    await _secureStorage.deleteAll();
    await prefs.setBool(installMarkerKey, true);
  }
}
