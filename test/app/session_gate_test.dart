import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/features/splash/states/splash_state.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  group('the session gate', () {
    test('no session starts on sign-in, whatever the onboarding state', () {
      expect(
        resolveStartRoute(loggedIn: false, needsProfile: true, needsStore: true),
        AppRoutes.signInName,
      );
      expect(
        resolveStartRoute(loggedIn: false, needsProfile: false, needsStore: false),
        AppRoutes.signInName,
      );
    });

    test('a session owing a profile starts on the profile screen', () {
      expect(
        resolveStartRoute(loggedIn: true, needsProfile: true, needsStore: true),
        AppRoutes.onboardingProfileName,
      );
    });

    test('profile outranks store when both are owed', () {
      expect(
        resolveStartRoute(loggedIn: true, needsProfile: true, needsStore: false),
        AppRoutes.onboardingProfileName,
      );
    });

    test('a session owing only a store starts on create-shop', () {
      expect(
        resolveStartRoute(loggedIn: true, needsProfile: false, needsStore: true),
        AppRoutes.createStoreName,
      );
    });

    test('a fully onboarded session starts on the dashboard', () {
      expect(
        resolveStartRoute(loggedIn: true, needsProfile: false, needsStore: false),
        AppRoutes.dashboardName,
      );
    });
  });
}
