import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/dashboard/pages/dashboard_page.dart';
import 'package:mine_storage/features/settings/pages/settings_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;
  late GoRouter router;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget app({required String initialLocation}) {
    final container = ProviderContainer(
      overrides: [
        authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
        storeRepositoryProvider.overrideWithValue(
          FakeStoreRepository(stores: [storeFixture()]),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
      ],
    );
    router = container.read(routerProvider);
    router.go(initialLocation);

    // The settings page reads `context.locale`, so the singleton `useLocale`
    // seeds is not enough — it needs a real EasyLocalization ancestor.
    return EasyLocalization(
      supportedLocales: const [enLocale, viLocale],
      path: 'assets/translations',
      fallbackLocale: enLocale,
      startLocale: enLocale,
      saveLocale: false,
      assetLoader: const FileAssetLoader(),
      child: Builder(
        builder: (context) {
          useLocale(context.locale);
          return UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              routerConfig: router,
              locale: context.locale,
              supportedLocales: context.supportedLocales,
              theme: AppTheme.light(),
              scaffoldMessengerKey: snackbarKey,
            ),
          );
        },
      ),
    );
  }

  String currentPath() => router.routeInformationProvider.value.uri.path;

  testWidgets('settings shows a back button in its app bar', (tester) async {
    await tester.pumpWidget(app(initialLocation: AppRoutes.settings));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsPage), findsOneWidget);
    expect(find.byType(BackButton), findsOneWidget);
  });

  testWidgets('back leaves settings for the dashboard when nothing can pop', (tester) async {
    await tester.pumpWidget(app(initialLocation: AppRoutes.settings));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(currentPath(), AppRoutes.dashboard);
    expect(find.byType(SettingsPage), findsNothing);
  });

  testWidgets('opening settings from the dashboard and going back returns to it', (tester) async {
    await tester.pumpWidget(app(initialLocation: AppRoutes.dashboard));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.settings_outlined));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsPage), findsOneWidget);

    await tester.tap(find.byType(BackButton));
    await tester.pumpAndSettle();

    expect(currentPath(), AppRoutes.dashboard);
    expect(find.byType(DashboardPage), findsOneWidget);
  });
}
