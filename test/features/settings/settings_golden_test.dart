import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/localization_test_harness.dart';

void main() {
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

  for (final (locale, tag) in [(enLocale, 'en'), (viLocale, 'vi')]) {
    testWidgets('settings golden · $tag', (tester) async {
      sizeToPhone(tester);
      await pumpLocalizedApp(
        tester,
        ProviderScope(
          overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
          child: Theme(data: AppTheme.light(), child: const SettingsPage()),
        ),
        locale: locale,
      );
      await expectLater(
        find.byType(SettingsPage),
        matchesGoldenFile('../../goldens/settings_$tag.png'),
      );
    });
  }
}
