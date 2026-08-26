import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';

/// The store products and figures are read and written against.
///
/// Onboarding writes it first; the store switcher (S07) is the only thing that
/// changes it afterwards. Null means onboarding never settled on one, which
/// every screen has to refuse rather than guess past.
final activeStoreProvider = NotifierProvider<ActiveStoreNotifier, String?>(
  ActiveStoreNotifier.new,
);

class ActiveStoreNotifier extends Notifier<String?> {
  @override
  String? build() =>
      ref.watch(sharedPreferencesProvider).getString(OnboardingResolver.activeStoreKey);

  Future<void> select(String storeId) async {
    // Leaving the aggregate is part of choosing a store: the two scopes are
    // alternatives, and holding both would leave the dashboard ambiguous.
    ref.read(allStoresScopeProvider.notifier).set(false);
    if (state == storeId) return;
    state = storeId;
    await ref
        .read(sharedPreferencesProvider)
        .setString(OnboardingResolver.activeStoreKey, storeId);
  }
}

/// The owner-only aggregate scope. Deliberately separate from the active store
/// id rather than a sentinel value inside it, so every existing reader of
/// [activeStoreProvider] keeps working unchanged.
final allStoresScopeProvider = NotifierProvider<AllStoresScopeNotifier, bool>(
  AllStoresScopeNotifier.new,
);

class AllStoresScopeNotifier extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;
}
