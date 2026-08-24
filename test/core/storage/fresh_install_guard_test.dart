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
    secureStore = {'supabase_session': '{"access_token":"abc"}'};
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
}
