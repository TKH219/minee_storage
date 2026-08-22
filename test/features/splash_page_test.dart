import '../support/fake_store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/splash/pages/splash_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../support/auth_test_harness.dart';
import '../support/fake_auth_repository.dart';

import '../support/localization_test_harness.dart';

Widget host(SharedPreferences prefs, {Brightness brightness = Brightness.light}) {
  final router = buildTestRouter();
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(stores: [storeFixture()]),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      routerProvider.overrideWithValue(router),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: const SplashPage(),
    ),
  );
}

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('splash carries the brand, the tagline and a bare spinner', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();

    expect(find.text('Mine Storage'), findsOneWidget);
    expect(find.text('Know what you hold.'), findsOneWidget);
    // The one place a bare spinner is right: nothing is known yet, so there is
    // no shape to promise. "Restoring your session" is the frame's annotation,
    // not on-screen copy.
    expect(find.byType(LottieAnimation), findsOneWidget);
    expect(find.byType(LabelledSpinner), findsNothing);
    expect(find.text('Restoring your session'), findsNothing);
  });

  testWidgets('splash sits on the neutral surface, not the brand colour', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    final scaffold = tester.widget<Scaffold>(find.byType(Scaffold));
    expect(scaffold.backgroundColor, const Color(0xFFFFFFFF));
  });

  testWidgets('the spinner is 48 square, 24 below the tagline', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    expect(tester.getSize(find.byType(LottieAnimation)), const Size(48, 48));
    expect(
      tester.getTopLeft(find.byType(LottieAnimation)).dy -
          tester.getBottomLeft(find.text('Know what you hold.')).dy,
      closeTo(24, 1.0),
    );
  });

  testWidgets('splash renders in dark mode too', (tester) async {
    await tester.pumpWidget(host(prefs, brightness: Brightness.dark));
    await tester.pump();
    expect(find.text('Know what you hold.'), findsOneWidget);
  });
}
