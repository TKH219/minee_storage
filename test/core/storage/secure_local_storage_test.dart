import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/core/storage/fresh_install_guard.dart';
import 'package:mine_storage/core/storage/secure_local_storage.dart';

import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> store;

  setUp(() {
    store = {};
    SharedPreferences.setMockInitialValues({
      FreshInstallGuard.installMarkerKey: true,
    });
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          final args = (call.arguments as Map?)?.cast<String, dynamic>() ?? {};
          switch (call.method) {
            case 'write':
              store[args['key'] as String] = args['value'] as String;
              return null;
            case 'read':
              return store[args['key'] as String];
            case 'delete':
              store.remove(args['key'] as String);
              return null;
            case 'containsKey':
              return store.containsKey(args['key'] as String);
            case 'deleteAll':
              store.clear();
              return null;
            case 'readAll':
              return store;
            default:
              return null;
          }
        });
  });

  test('round-trips a session through secure storage', () async {
    final storage = SecureLocalStorage();

    expect(await storage.hasAccessToken(), isFalse);

    await storage.persistSession('{"access_token":"abc"}');

    expect(await storage.hasAccessToken(), isTrue);
    expect(await storage.accessToken(), '{"access_token":"abc"}');
  });

  test('removePersistedSession clears the entry', () async {
    final storage = SecureLocalStorage();
    await storage.persistSession('{"access_token":"abc"}');

    await storage.removePersistedSession();

    expect(await storage.hasAccessToken(), isFalse);
    expect(await storage.accessToken(), isNull);
  });

  test('initialize discards a session left by a previous install', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = SecureLocalStorage();
    await storage.persistSession('{"access_token":"abc"}');

    await storage.initialize();

    expect(await storage.hasAccessToken(), isFalse);
  });

  test('initialize keeps the session of an install already seen', () async {
    final storage = SecureLocalStorage();
    await storage.persistSession('{"access_token":"abc"}');

    await storage.initialize();

    expect(await storage.hasAccessToken(), isTrue);
  });
}
