import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme_mode_provider.dart';
import 'package:mine_storage/core/storage/fresh_install_guard.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';

import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> secureStore;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    secureStore = {'supabase_session': '{"access_token":"abc"}', 'other': 'x'};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          switch (call.method) {
            case 'deleteAll':
              secureStore.clear();
              return null;
            case 'readAll':
              return secureStore;
            default:
              return null;
          }
        });
  });

  UserStatePurger purger() => UserStatePurger();

  test('empties secure storage', () async {
    await purger().purge();

    expect(secureStore, isEmpty);
  });

  test('clears user preferences but keeps the device safe-list', () async {
    SharedPreferences.setMockInitialValues({
      ThemeModeNotifier.storageKey: 'dark',
      'cached_products': '[]',
      'last_shop_name': 'Mine',
    });

    await purger().purge();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeModeNotifier.storageKey), 'dark');
    expect(prefs.getKeys(), {ThemeModeNotifier.storageKey});
  });

  test('a key added later is purged by default', () async {
    SharedPreferences.setMockInitialValues({'some_future_cache': 'value'});

    await purger().purge();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getKeys(), isEmpty);
  });

  test('keeps the install marker so the next launch is not read as a reinstall', () async {
    SharedPreferences.setMockInitialValues({
      FreshInstallGuard.installMarkerKey: true,
      'cached_products': '[]',
    });

    await purger().purge();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(FreshInstallGuard.installMarkerKey), isTrue);
  });
}
