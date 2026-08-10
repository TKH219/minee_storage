import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:mine_storage/app/theme/theme_mode_provider.dart';
import 'package:mine_storage/core/storage/user_state_purger.dart';
import 'package:mine_storage/providers.dart';

import '../support/fake_auth_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
  late Map<String, String> secureStore;
  late FakeAuthRepository repository;

  setUp(() {
    secureStore = {'supabase_session': '{"access_token":"abc"}'};
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'deleteAll') secureStore.clear();
          return null;
        });
    SharedPreferences.setMockInitialValues({
      ThemeModeNotifier.storageKey: 'dark',
      'cached_products': '[]',
    });
    repository = FakeAuthRepository();
  });

  ProviderContainer buildContainer() {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        // Only read for the initial value; never issues a request here.
        supabaseClientProvider.overrideWithValue(
          SupabaseClient('http://localhost', 'test-anon-key'),
        ),
      ],
    );
    addTearDown(container.dispose);
    // Subscribing is what starts the listener.
    container.read(authStateListenableProvider);
    return container;
  }

  test('losing the session purges stored user state', () async {
    buildContainer();

    repository.authStateController.add(false);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(secureStore, isEmpty);
    expect(prefs.getKeys(), {ThemeModeNotifier.storageKey});
  });

  test('signing in does not purge', () async {
    buildContainer();

    repository.authStateController.add(true);
    await Future<void>.delayed(Duration.zero);

    final prefs = await SharedPreferences.getInstance();
    expect(secureStore, isNotEmpty);
    expect(prefs.getKeys(), contains('cached_products'));
  });

  test('the listenable still tracks the session for the router', () async {
    final container = buildContainer();
    final listenable = container.read(authStateListenableProvider);

    repository.authStateController.add(true);
    await Future<void>.delayed(Duration.zero);
    expect(listenable.value, isTrue);

    repository.authStateController.add(false);
    await Future<void>.delayed(Duration.zero);
    expect(listenable.value, isFalse);
  });

  test('the purger keeps device settings but drops user data', () async {
    await UserStatePurger().purge();

    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString(ThemeModeNotifier.storageKey), 'dark');
    expect(prefs.getKeys(), isNot(contains('cached_products')));
  });
}
