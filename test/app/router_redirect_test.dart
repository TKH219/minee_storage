import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';

void main() {
  test('sends a signed-out user away from home', () {
    expect(resolveRedirect(loggedIn: false, location: AppRoutes.home), AppRoutes.signIn);
  });

  test('lets a signed-out user reach the auth routes', () {
    expect(resolveRedirect(loggedIn: false, location: AppRoutes.signIn), isNull);
    expect(resolveRedirect(loggedIn: false, location: AppRoutes.signUp), isNull);
  });

  test('sends a signed-in user away from sign-in and sign-up', () {
    expect(resolveRedirect(loggedIn: true, location: AppRoutes.signIn), AppRoutes.home);
    expect(resolveRedirect(loggedIn: true, location: AppRoutes.signUp), AppRoutes.home);
  });

  test('leaves a signed-in user on forgot-password mid-reset', () {
    expect(resolveRedirect(loggedIn: true, location: AppRoutes.forgotPassword), isNull);
  });

  test('never redirects away from splash', () {
    expect(resolveRedirect(loggedIn: false, location: AppRoutes.splash), isNull);
    expect(resolveRedirect(loggedIn: true, location: AppRoutes.splash), isNull);
  });
}
