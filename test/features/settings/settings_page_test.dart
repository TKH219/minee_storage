import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:mine_storage/features/settings/widgets/settings_metrics.dart';
import 'package:mine_storage/features/settings/widgets/settings_tile.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/localization_test_harness.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  /// The settings list is taller than the default test window, and a ListView
  /// does not build what it cannot show.
  void useTallFrame(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget host() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          user: const UserEntity(
            id: 'uid-1',
            email: 'maya@northsidegrocers.com',
            fullName: 'Northside Grocers',
          ),
        ),
      ),
    ],
    child: Theme(data: AppTheme.light(), child: const SettingsPage()),
  );

  /// The Coming-soon surface is a snack bar read off [snackbarKey], so the
  /// tests that assert it need an app that owns a messenger.
  Widget hostWithMessenger() => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      authRepositoryProvider.overrideWithValue(
        FakeAuthRepository(
          user: const UserEntity(
            id: 'uid-1',
            email: 'maya@northsidegrocers.com',
            fullName: 'Northside Grocers',
          ),
        ),
      ),
    ],
    // A ScaffoldMessenger widget rather than a second MaterialApp: the page
    // reads context.locale, which only resolves inside the harness's own
    // EasyLocalization ancestor.
    child: Theme(
      data: AppTheme.light(),
      child: ScaffoldMessenger(
        key: snackbarKey,
        child: const SettingsPage(),
      ),
    ),
  );

  group('the account group', () {
    testWidgets('heads the page with the signed-in account', (tester) async {
      useTallFrame(tester);
      await pumpLocalizedApp(tester, host());

      expect(find.text('Northside Grocers'), findsOneWidget);
      expect(find.text('maya@northsidegrocers.com'), findsOneWidget);
    });

    testWidgets('offers profile, password and the updates toggle', (tester) async {
      useTallFrame(tester);
      await pumpLocalizedApp(tester, host());

      expect(find.text('My profile'), findsOneWidget);
      expect(find.text('Change password'), findsOneWidget);
      expect(find.text('Allow profile updates'), findsOneWidget);
      expect(find.byKey(const Key('settings-allow-updates')), findsOneWidget);
    });

    testWidgets('My profile is inert and says so', (tester) async {
      useTallFrame(tester);
      await pumpLocalizedApp(tester, hostWithMessenger());

      await tester.tap(find.text('My profile'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget, reason: 'it navigates nowhere');
    });

    testWidgets('Change password is inert and says so', (tester) async {
      useTallFrame(tester);
      await pumpLocalizedApp(tester, hostWithMessenger());

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(find.text('Coming soon'), findsOneWidget);
    });

    testWidgets('the updates toggle starts on and persists when turned off',
        (tester) async {
        useTallFrame(tester);
      await pumpLocalizedApp(tester, host());

      final before = tester.widget<Switch>(
        find.descendant(
          of: find.byKey(const Key('settings-allow-updates')),
          matching: find.byType(Switch),
        ),
      );
      expect(before.value, isTrue);

      await tester.tap(find.byKey(const Key('settings-allow-updates')));
      await tester.pumpAndSettle();

      final after = tester.widget<Switch>(
        find.descendant(
          of: find.byKey(const Key('settings-allow-updates')),
          matching: find.byType(Switch),
        ),
      );
      expect(after.value, isFalse);
      expect(prefs.getBool('settings_allow_profile_updates'), isFalse);
    });
  });

  group('grouping', () {
    testWidgets('runs account, then preferences, then the way out',
        (tester) async {
        useTallFrame(tester);
      await pumpLocalizedApp(tester, host());

      final profile = tester.getTopLeft(find.text('My profile')).dy;
      final preferences = tester.getTopLeft(find.text('Preferences')).dy;
      final currency = tester.getTopLeft(find.text('Currency')).dy;
      final logOut = tester.getTopLeft(find.text('Log out')).dy;

      expect(profile, lessThan(preferences));
      expect(preferences, lessThan(currency));
      expect(currency, lessThan(logOut));
    });

    testWidgets('puts Currency above Theme, as the design does', (tester) async {
      useTallFrame(tester);
      await pumpLocalizedApp(tester, host());

      expect(
        tester.getTopLeft(find.text('Currency')).dy,
        lessThan(tester.getTopLeft(find.text('Theme')).dy),
      );
    });

    testWidgets('keeps the language row the localization spec shipped',
        (tester) async {
        useTallFrame(tester);
      await pumpLocalizedApp(tester, host());
      expect(find.text('Language'), findsOneWidget);
    });

    testWidgets('draws Log out as the destructive one', (tester) async {
      useTallFrame(tester);
      await pumpLocalizedApp(tester, host());

      final label = tester.widget<Text>(find.text('Log out'));
      final context = tester.element(find.byType(SettingsPage));
      expect(label.style?.color, context.colors.red5);
    });
  });

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
    useTallFrame(tester);
    await pumpLocalizedApp(tester, host());

    final tiles = tester.widgetList<SettingsTile>(find.byType(SettingsTile)).toList();
    expect(
      tiles.length,
      7,
      reason: 'profile, password, updates, currency, theme, language, log out',
    );

    final sizes = find.byType(SettingsTile).evaluate().map((e) => tester.getSize(find.byWidget(e.widget))).toList();
    for (final size in sizes) {
      expect(size.height, SettingsMetrics.tileMinHeight);
      expect(size.width, sizes.first.width);
    }
  });
}
