import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mine_storage/app/env/env.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/app.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/storage/fresh_install_guard.dart';
import 'package:mine_storage/core/storage/secure_local_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  // Ahead of anything that reads the keychain: a reinstall inherits the
  // previous install's entries, and they have to be gone before the app can
  // act on them. Repeated by SecureLocalStorage.initialize, which is harmless.
  await FreshInstallGuard().clearCredentialsIfReinstalled();

  // Opened here so the theme provider can read synchronously from the very
  // first frame — otherwise the app flashes the wrong brightness on launch.
  final sharedPreferences = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: Env.apiUrl,
    publishableKey: Env.anonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      // startLocale only applies while nothing is saved, so a fresh install is
      // English whatever the device language, and a returning user keeps the
      // language they chose.
      startLocale: const Locale('en'),
      child: ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(sharedPreferences),
        ],
        child: const App(),
      ),
    ),
  );
}
