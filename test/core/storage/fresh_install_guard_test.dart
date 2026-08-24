import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/core/storage/fresh_install_guard.dart';

import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> secureStore;

  setUp(() {
    secureStore = {
      'supabase_session': '{"access_token":"abc"}',
      'pin_code': '1234',
      'cached_token': 'xyz',
    };
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

  test('drops a session the keychain kept from a previous install', () async {
    SharedPreferences.setMockInitialValues({});

    await FreshInstallGuard().clearCredentialsIfReinstalled();

    expect(secureStore, isEmpty);
  });

  test('marks the install so the next launch is left alone', () async {
    SharedPreferences.setMockInitialValues({});

    await FreshInstallGuard().clearCredentialsIfReinstalled();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(FreshInstallGuard.installMarkerKey), isTrue);
  });

  test('keeps the session on every launch after the first', () async {
    SharedPreferences.setMockInitialValues({
      FreshInstallGuard.installMarkerKey: true,
    });

    await FreshInstallGuard().clearCredentialsIfReinstalled();

    expect(secureStore, isNotEmpty);
  });

  test('wipes every secure entry, not just the session', () async {
    SharedPreferences.setMockInitialValues({});

    await FreshInstallGuard().clearCredentialsIfReinstalled();

    expect(secureStore, isEmpty);
  });

  test('install, relaunch, reinstall', () async {
    // First install: nothing of the previous install may survive.
    SharedPreferences.setMockInitialValues({});
    await FreshInstallGuard().clearCredentialsIfReinstalled();
    expect(secureStore, isEmpty);

    // The user signs in, so the session is written.
    secureStore['supabase_session'] = '{"access_token":"fresh"}';

    // Closing and reopening keeps it.
    await FreshInstallGuard().clearCredentialsIfReinstalled();
    expect(secureStore['supabase_session'], '{"access_token":"fresh"}');

    // Uninstalling takes the preferences with it; the keychain keeps its
    // entries. Reinstalling must therefore start empty again.
    SharedPreferences.setMockInitialValues({});
    await FreshInstallGuard().clearCredentialsIfReinstalled();
    expect(secureStore, isEmpty);
  });

  test('running twice on one launch is harmless', () async {
    SharedPreferences.setMockInitialValues({});
    final guard = FreshInstallGuard();

    await guard.clearCredentialsIfReinstalled();
    secureStore['supabase_session'] = '{"access_token":"fresh"}';
    await guard.clearCredentialsIfReinstalled();

    expect(secureStore['supabase_session'], '{"access_token":"fresh"}');
  });
}
