import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/pages/main_shell_page.dart';
import 'package:mine_storage/features/shell/widgets/add_action_button.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_auth_repository.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<GoRouter> pumpShell(WidgetTester tester) async {
    final router = GoRouter(
      initialLocation: AppRoutes.home,
      routes: [buildAppShellRoute()],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('starts on Home inside the shell', (tester) async {
    await pumpShell(tester);

    expect(find.byType(MainShellPage), findsOneWidget);
    expect(find.text('Home is not built yet'), findsOneWidget);
  });

  testWidgets('each branch renders its own screen', (tester) async {
    final router = await pumpShell(tester);

    router.goNamed(AppRoutes.reportsName);
    await tester.pumpAndSettle();
    expect(find.text('No reports yet'), findsOneWidget);

    router.goNamed(AppRoutes.settingsName);
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);
  });

  testWidgets('keeps every branch alive across switches', (tester) async {
    final router = await pumpShell(tester);

    router.goNamed(AppRoutes.settingsName);
    await tester.pumpAndSettle();

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();
    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );

    router.goNamed(AppRoutes.homeName);
    await tester.pumpAndSettle();
    router.goNamed(AppRoutes.settingsName);
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('the bar switches branches', (tester) async {
    await pumpShell(tester);

    await tester.tap(find.text('Report'));
    await tester.pumpAndSettle();
    expect(find.text('No reports yet'), findsOneWidget);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    expect(find.text('My profile'), findsOneWidget);
  });

  testWidgets('the Add button announces that adding is coming soon', (
    tester,
  ) async {
    await pumpShell(tester);

    await tester.tap(find.byType(AddActionButton));
    await tester.pump();

    expect(find.text('Adding items is coming soon'), findsOneWidget);
  });
}
