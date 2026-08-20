import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/splash/pages/splash_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/auth_test_harness.dart';
import '../support/fake_auth_repository.dart';
import '../support/localization_test_harness.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host() => ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      routerProvider.overrideWithValue(buildTestRouter()),
    ],
    child: Theme(data: AppTheme.light(), child: const SplashPage()),
  );

  testWidgets('splash tagline renders English by default', (tester) async {
    await pumpLocalized(tester, host(), settle: false);
    expect(find.text('Know what you hold.'), findsOneWidget);
  });

  testWidgets('splash tagline translates to Vietnamese', (tester) async {
    await pumpLocalized(tester, host(), locale: viLocale, settle: false);
    expect(find.text('Biết rõ bạn đang có gì.'), findsOneWidget);
  });
}
