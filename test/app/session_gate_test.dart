import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/features/splash/states/splash_state.dart';

void main() {
  group('the session gate', () {
    test('a restored session starts on home', () {
      expect(resolveStartRoute(loggedIn: true), AppRoutes.homeName);
    });

    test('no session starts on sign-in', () {
      expect(resolveStartRoute(loggedIn: false), AppRoutes.signInName);
    });
  });
}
