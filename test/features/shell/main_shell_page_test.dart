import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/app_nav_bar.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

Widget shellApp({
  required String initialLocation,
  required SharedPreferences prefs,
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

  testWidgets('the reports tab renders its placeholder under the bar', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/reports', prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.text('Nothing to report yet'), findsOneWidget);
  });

  testWidgets('every tab keeps the bar present', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/reports', prefs: prefs));
    await tester.pumpAndSettle();

    for (final tab in ['Dashboard', 'Products', 'Sales']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.byType(AppNavBar), findsOneWidget, reason: tab);
    }
  });

  testWidgets('splash and sign-in show no navigation bar', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/sign-in', prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.byType(AppNavBar), findsNothing);
  });

  testWidgets('the centre action shows a snack rather than navigating', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/reports', prefs: prefs));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new-sale-circle')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Nothing to report yet'), findsOneWidget);
    expect(find.byType(SnackBar), findsOneWidget);
  });
}
