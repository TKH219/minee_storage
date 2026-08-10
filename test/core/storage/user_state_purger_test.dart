import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme_mode_provider.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';

void main() {
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

  UserStatePurger purger({Future<void> Function()? signOut}) {
    return UserStatePurger(signOut: signOut ?? () async {});
  }

  test('signs out, then empties secure storage', () async {
    var signedOut = false;
    await purger(signOut: () async => signedOut = true).purge();

    expect(signedOut, isTrue);
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

  test('a failing sign-out still clears local state', () async {
    SharedPreferences.setMockInitialValues({'cached_products': '[]'});

    await purger(signOut: () async => throw Exception('network down')).purge();

    final prefs = await SharedPreferences.getInstance();
    expect(secureStore, isEmpty);
    expect(prefs.getKeys(), isEmpty);
  });
}
