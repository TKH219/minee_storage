import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:mine_storage/providers.dart';

import '../support/fake_auth_repository.dart';

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpSettings(
    WidgetTester tester,
    FakeAuthRepository repository,
  ) {
    final router = GoRouter(
      initialLocation: AppRoutes.settings,
      routes: [
        GoRoute(
          path: AppRoutes.settings,
          name: AppRoutes.settingsName,
          builder: (context, state) => const SettingsPage(),
        ),
        GoRoute(
          path: AppRoutes.signIn,
          name: AppRoutes.signInName,
          builder: (context, state) =>
              const Scaffold(body: Text('sign in screen')),
        ),
      ],
    );

    return tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          authRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
  }

  FakeAuthRepository signedIn({String id = 'user-1'}) {
    return FakeAuthRepository(
      user: UserEntity(id: id, email: 'a@b.co', shopName: 'Shop'),
    );
  }

  testWidgets('renders every settings row', (tester) async {
    await pumpSettings(tester, signedIn());
    await tester.pumpAndSettle();

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('My profile'), findsOneWidget);
    expect(find.text('Change password'), findsOneWidget);
    expect(find.text('Allow profile updates'), findsOneWidget);
    expect(find.text('Theme'), findsOneWidget);
    expect(find.text('Log out'), findsOneWidget);
  });

  testWidgets('shows the signed-in user id in the header', (tester) async {
    await pumpSettings(tester, signedIn(id: 'user-42'));
    await tester.pumpAndSettle();

    expect(find.text('user-42'), findsOneWidget);
  });

  testWidgets('shows a dash when there is no session', (tester) async {
    await pumpSettings(tester, FakeAuthRepository());
    await tester.pumpAndSettle();

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('inert rows only announce that they are coming soon', (
    tester,
  ) async {
    await pumpSettings(tester, signedIn());
    await tester.pumpAndSettle();

    await tester.tap(find.text('My profile'));
    await tester.pump();

    expect(find.text('My profile is coming soon'), findsOneWidget);
  });

  testWidgets('the profile-updates switch flips its provider', (tester) async {
    await pumpSettings(tester, signedIn());
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isTrue,
    );

    await tester.tap(find.byType(SwitchListTile));
    await tester.pumpAndSettle();

    expect(
      tester.widget<SwitchListTile>(find.byType(SwitchListTile)).value,
      isFalse,
    );
  });

  testWidgets('log out asks for confirmation before doing anything', (
    tester,
  ) async {
    final repository = signedIn();
    await pumpSettings(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();

    expect(find.text('Log out?'), findsOneWidget);
    expect(repository.calls.contains('signOut'), isFalse);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(repository.calls.contains('signOut'), isFalse);
  });

  testWidgets('confirming log out clears the session and lands on sign in', (
    tester,
  ) async {
    final repository = signedIn();
    await pumpSettings(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Log out'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(TextButton, 'Log out'));
    await tester.pumpAndSettle();

    expect(repository.calls.where((c) => c == 'signOut').length, 1);
    expect(find.text('sign in screen'), findsOneWidget);
  });
}
