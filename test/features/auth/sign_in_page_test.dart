import '../../support/fake_store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/features/auth/sign_in/pages/sign_in_page.dart';
import 'package:mine_storage/features/auth/widgets/auth_error_banner.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';

Widget host(
  SharedPreferences prefs, {
  Object? error,
  Duration delay = Duration.zero,
  bool passwordWasReset = false,
  Brightness brightness = Brightness.light,
}) {
  return ProviderScope(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository(error: error, delay: delay)),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(stores: [storeFixture()]),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      routerProvider.overrideWithValue(buildTestRouter()),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: SignInPage(passwordWasReset: passwordWasReset),
    ),
  );
}

Future<void> submit(WidgetTester tester) async {
  await tester.enterText(find.byType(TextField).first, 'maya@northsidegrocers.com');
  await tester.enterText(find.byType(TextField).last, 'secret');
  await tester.pump();
  await tester.tap(find.text('Sign in'));
  await tester.pumpAndSettle();
}

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('no social sign-in buttons while the feature is off', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();

    expect(find.text('Google'), findsNothing);
    expect(find.text('Apple'), findsNothing);
    expect(find.text('or continue with'), findsNothing);
  });

  testWidgets('the password field reveals and re-hides from its own eye', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();

    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isTrue);

    await tester.tap(find.byTooltip('Show password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isFalse);

    await tester.tap(find.byTooltip('Hide password'));
    await tester.pump();
    expect(tester.widget<TextField>(find.byType(TextField).last).obscureText, isTrue);
  });

  testWidgets('only the password field carries an eye', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    expect(find.byTooltip('Show password'), findsOneWidget);
  });

  testWidgets('carries the design copy', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in to pick up where your stock left off.'), findsOneWidget);
    expect(find.byType(AppTextField), findsNWidgets(2));
  });

  testWidgets('wrong credentials render below the password field', (tester) async {
    await tester.pumpWidget(host(prefs, error: const InvalidCredentialsException()));
    await tester.pump();
    await submit(tester);

    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(AuthErrorBanner)).dy,
      greaterThan(tester.getTopLeft(find.byType(AppTextField).last).dy),
    );
  });

  testWidgets('a deactivated account renders above the email field', (tester) async {
    await tester.pumpWidget(host(
      prefs,
      error: const ForbiddenException(message: 'This account has been deactivated.'),
    ));
    await tester.pump();
    await submit(tester);

    expect(find.byType(AuthErrorBanner), findsOneWidget);
    expect(
      tester.getTopLeft(find.byType(AuthErrorBanner)).dy,
      lessThan(tester.getTopLeft(find.byType(AppTextField).first).dy),
    );
  });

  testWidgets('the deactivated frame hides the forgot-password link', (tester) async {
    await tester.pumpWidget(host(
      prefs,
      error: const ForbiddenException(message: 'This account has been deactivated.'),
    ));
    await tester.pump();
    await submit(tester);
    expect(find.text('Forgot password?'), findsNothing);
  });

  testWidgets('the forgot-password link is present by default', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    expect(find.text('Forgot password?'), findsOneWidget);
  });

  testWidgets('no error surface names which credential was wrong', (tester) async {
    await tester.pumpWidget(host(prefs, error: const InvalidCredentialsException()));
    await tester.pump();
    await submit(tester);
    final banner = tester.widget<AuthErrorBanner>(find.byType(AuthErrorBanner));
    expect(banner.message.toLowerCase(), isNot(contains('email is')));
    expect(banner.message.toLowerCase(), isNot(contains('password is')));
  });

  testWidgets('submitting shows in-button dots without resizing the button', (tester) async {
    await tester.pumpWidget(host(prefs, delay: const Duration(milliseconds: 300)));
    await tester.pump();

    final restingSize = tester.getSize(find.byType(FilledButton));

    await tester.enterText(find.byType(TextField).first, 'maya@northsidegrocers.com');
    await tester.enterText(find.byType(TextField).last, 'secret');
    await tester.pump();
    await tester.tap(find.text('Sign in'));
    await tester.pump();

    expect(find.byType(ButtonDots), findsOneWidget);
    expect(tester.getSize(find.byType(FilledButton)), restingSize);

    await tester.pumpAndSettle();
  });

  testWidgets('returning from a reset shows a success banner, not an error', (tester) async {
    await tester.pumpWidget(host(prefs, passwordWasReset: true));
    await tester.pump();

    expect(find.text('Password updated. Sign in with your new one.'), findsOneWidget);
    final banner = tester.widget<AuthErrorBanner>(find.byType(AuthErrorBanner));
    expect(banner.tone, AuthBannerTone.success);
  });
}
