import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/pages/main_shell_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

Widget shellApp({
  required String initialLocation,
  required SharedPreferences prefs,
  required ThemeMode themeMode,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );
  final router = container.read(routerProvider);
  router.go(initialLocation);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      scaffoldMessengerKey: snackbarKey,
    ),
  );
}

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  for (final (name, mode) in [
    ('light', ThemeMode.light),
    ('dark', ThemeMode.dark),
  ]) {
    testWidgets('reports tab matches its $name golden at 390x844', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        shellApp(initialLocation: '/reports', prefs: prefs, themeMode: mode),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MainShellPage),
        matchesGoldenFile('../../goldens/shell_reports_$name.png'),
      );
    });
  }
}
