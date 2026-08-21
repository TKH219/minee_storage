import '../../support/fake_store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/features/auth/sign_in/pages/sign_in_page.dart';
import 'package:mine_storage/features/splash/pages/splash_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';

Widget host(Widget child, SharedPreferences prefs, {Object? error, required ThemeMode mode}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(error: error)),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(stores: [storeFixture()]),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      routerProvider.overrideWithValue(buildTestRouter()),
    ],
    child: MaterialApp(
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: mode,
      home: child,
    ),
  );
}

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  void sizeToPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  for (final (name, mode) in [('light', ThemeMode.light), ('dark', ThemeMode.dark)]) {
    testWidgets('splash golden · $name', (tester) async {
      sizeToPhone(tester);
      await tester.pumpWidget(host(const SplashPage(), prefs, mode: mode));
      await tester.pump();
      await expectLater(
        find.byType(SplashPage),
        matchesGoldenFile('../../goldens/auth_splash_$name.png'),
      );
    });

    testWidgets('sign-in default golden · $name', (tester) async {
      sizeToPhone(tester);
      await tester.pumpWidget(host(const SignInPage(), prefs, mode: mode));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SignInPage),
        matchesGoldenFile('../../goldens/auth_sign_in_$name.png'),
      );
    });
  }

  // Vietnamese runs longer than English, so these catch truncation the English
  // goldens cannot.
  for (final (name, mode) in [('light', ThemeMode.light), ('dark', ThemeMode.dark)]) {
    testWidgets('splash golden · vi · $name', (tester) async {
      useLocale(viLocale);
      sizeToPhone(tester);
      await tester.pumpWidget(host(const SplashPage(), prefs, mode: mode));
      await tester.pump();
      await expectLater(
        find.byType(SplashPage),
        matchesGoldenFile('../../goldens/auth_splash_vi_$name.png'),
      );
    });

    testWidgets('sign-in default golden · vi · $name', (tester) async {
      useLocale(viLocale);
      sizeToPhone(tester);
      await tester.pumpWidget(host(const SignInPage(), prefs, mode: mode));
      await tester.pumpAndSettle();
      await expectLater(
        find.byType(SignInPage),
        matchesGoldenFile('../../goldens/auth_sign_in_vi_$name.png'),
      );
    });
  }

  testWidgets('sign-in deactivated golden', (tester) async {
    sizeToPhone(tester);
    await tester.pumpWidget(host(
      const SignInPage(),
      prefs,
      error: const ForbiddenException(
        message: 'This account has been deactivated. Contact support to get it reopened.',
      ),
      mode: ThemeMode.light,
    ));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'sam@northsidegrocers.com');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(SignInPage),
      matchesGoldenFile('../../goldens/auth_sign_in_deactivated.png'),
    );
  });
}
