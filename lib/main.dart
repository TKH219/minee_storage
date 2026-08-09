import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/app.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/storage/secure_local_storage.dart';
import 'package:mine_storage/env/env.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Opened here so the theme provider can read synchronously from the very
  // first frame — otherwise the app flashes the wrong brightness on launch.
  final sharedPreferences = await SharedPreferences.getInstance();

  await Supabase.initialize(
    url: Env.apiUrl,
    publishableKey: Env.anonKey,
    authOptions: FlutterAuthClientOptions(localStorage: SecureLocalStorage()),
  );

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const App(),
    ),
  );
}
