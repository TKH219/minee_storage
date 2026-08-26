import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:mine_storage/features/settings/widgets/theme_picker_sheet.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/localization_test_harness.dart';

void main() {
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  void useTallFrame(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(390, 1200)
      ..devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Future<void> pumpSettings(WidgetTester tester, {Locale locale = enLocale}) async {
    useTallFrame(tester);
    container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        authRepositoryProvider.overrideWithValue(
          FakeAuthRepository(
            user: const UserEntity(id: 'uid-1', email: 'maya@example.com'),
          ),
        ),
      ],
    );
    addTearDown(container.dispose);

    await pumpLocalizedApp(
      tester,
      UncontrolledProviderScope(
        container: container,
        child: Theme(data: AppTheme.light(), child: const SettingsPage()),
      ),
      locale: locale,
    );
  }

  testWidgets('the theme row opens a picker rather than cycling', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    expect(find.byType(ThemePickerSheet), findsOneWidget);
    expect(find.text('System'), findsWidgets);
    expect(find.text('Light'), findsOneWidget);
    expect(find.text('Dark'), findsOneWidget);
  });

  testWidgets('the current mode is the one marked', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ThemePickerSheet));
    final system = tester.widget<Container>(
      find.byKey(const Key('theme-radio-system')),
    );
    final dark = tester.widget<Container>(
      find.byKey(const Key('theme-radio-dark')),
    );

    expect(
      ((system.decoration! as BoxDecoration).border! as Border).top.color,
      context.colors.primary4,
    );
    expect(
      ((dark.decoration! as BoxDecoration).border! as Border).top.color,
      context.colors.neutral4,
    );
  });

  testWidgets('choosing dark drives the theme and persists it', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-tile-dark')));
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.dark);
    expect(prefs.getString(ThemeModeNotifier.storageKey), 'dark');
    expect(find.byType(ThemePickerSheet), findsNothing);
  });

  testWidgets('the row follows the mode that was chosen', (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('theme-tile-light')));
    await tester.pumpAndSettle();

    expect(find.text('Light'), findsOneWidget);
  });

  testWidgets('dismissing without choosing leaves the mode alone',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Theme'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.byType(ThemePickerSheet))).pop();
    await tester.pumpAndSettle();

    expect(container.read(themeModeProvider), ThemeMode.system);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpSettings(tester, locale: viLocale);

    await tester.tap(find.text('Giao diện'));
    await tester.pumpAndSettle();

    expect(find.text('Sáng'), findsOneWidget);
    expect(find.textContaining('settings.'), findsNothing);
  });
}
