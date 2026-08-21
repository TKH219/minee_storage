import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/domain/repositories/auth_repository.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';
import 'package:mine_storage/features/splash/states/splash_state.dart';
import 'package:mine_storage/shared/utils/logger.dart';

/// Works out where a session belongs, from data rather than a stored step
/// counter, so a half-finished onboarding heals itself on the next launch.
class OnboardingResolver {
  OnboardingResolver(this._authRepository, this._storeRepository, this._preferences);

  static const String activeStoreKey = 'active_store_id';

  final AuthRepository _authRepository;
  final StoreRepository _storeRepository;
  final Future<SharedPreferences> Function() _preferences;

  Future<String> resolve() async {
    final user = await _authRepository.currentUser();
    if (user == null) {
      return resolveStartRoute(loggedIn: false, needsProfile: false, needsStore: false);
    }

    if (user.needsProfile) {
      return resolveStartRoute(loggedIn: true, needsProfile: true, needsStore: true);
    }

    final stores = await _storeRepository.listMine();
    if (stores.isEmpty) {
      return resolveStartRoute(loggedIn: true, needsProfile: false, needsStore: true);
    }

    // Remembering the active store is a convenience; failing to write it must
    // not bounce a fully onboarded user back to sign-in.
    try {
      final prefs = await _preferences();
      await prefs.setString(activeStoreKey, stores.first.id);
    } on Object catch (e) {
      logger.w('Failed to persist the active store id', error: e);
    }

    if (user.onboardingCompletedAt == null) {
      await _authRepository.completeOnboarding();
    }

    return resolveStartRoute(loggedIn: true, needsProfile: false, needsStore: false);
  }
}
