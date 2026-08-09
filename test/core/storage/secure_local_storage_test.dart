import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/storage/secure_local_storage.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> store;

  setUp(() {
    store = {};
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
}
