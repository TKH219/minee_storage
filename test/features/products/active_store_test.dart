import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';

void main() {
  Future<ProviderContainer> containerWith(Map<String, Object> values) async {
    SharedPreferences.setMockInitialValues(values);
    final prefs = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('reads the store onboarding settled on', () async {
    final container = await containerWith({
      OnboardingResolver.activeStoreKey: 'store-a',
    });

    expect(container.read(activeStoreProvider), 'store-a');
  });

  test('is null when onboarding never chose one', () async {
    final container = await containerWith({});

    expect(container.read(activeStoreProvider), isNull);
  });
}
