import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:mine_storage/features/settings/widgets/settings_metrics.dart';
import 'package:mine_storage/features/settings/widgets/settings_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/localization_test_harness.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget host() => ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: Theme(data: AppTheme.light(), child: const SettingsPage()),
  );

  testWidgets('shows a theme row, a language row and a currency row', (tester) async {
    await pumpLocalizedApp(tester, host());

    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Language'), findsOneWidget);
    expect(find.text('Currency'), findsOneWidget);
    expect(find.text('System'), findsOneWidget);
    expect(find.text('English'), findsOneWidget);
    // The VND default stands in until the currencies table answers.
    expect(find.text('VND ₫'), findsOneWidget);
  });

  testWidgets('the whole page translates to Vietnamese', (tester) async {
    await pumpLocalizedApp(tester, host(), locale: viLocale);

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Tuỳ chọn'), findsOneWidget);
    expect(find.text('Giao diện'), findsOneWidget);
    expect(find.text('Ngôn ngữ'), findsOneWidget);
    expect(find.text('Tiền tệ'), findsOneWidget);
  });

  testWidgets('the picker names each language in its own language', (tester) async {
    await pumpLocalizedApp(tester, host(), locale: viLocale);

    await tester.tap(find.text('Ngôn ngữ'));
    await tester.pumpAndSettle();

    // someone stranded in a language they cannot read must still find their own
    expect(find.text('English'), findsOneWidget);
    expect(find.text('Tiếng Việt'), findsWidgets);
  });

  testWidgets('choosing a language retranslates in place, with no restart', (tester) async {
    await pumpLocalizedApp(tester, host());
    expect(find.text('Settings'), findsOneWidget);

    await tester.tap(find.text('Language'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tiếng Việt'));
    await tester.pumpAndSettle();

    expect(find.text('Cài đặt'), findsOneWidget);
    expect(find.text('Giao diện'), findsOneWidget);
    expect(find.text('Settings'), findsNothing);
  });

  testWidgets('every row shares the same geometry', (tester) async {
    await pumpLocalizedApp(tester, host());

    final tiles = tester.widgetList<SettingsTile>(find.byType(SettingsTile)).toList();
    expect(tiles.length, 3);

    final sizes = find.byType(SettingsTile).evaluate().map((e) => tester.getSize(find.byWidget(e.widget))).toList();
    for (final size in sizes) {
      expect(size.height, SettingsMetrics.tileMinHeight);
      expect(size.width, sizes.first.width);
    }
  });
}
