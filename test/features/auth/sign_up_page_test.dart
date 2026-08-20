import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/auth/sign_up/pages/sign_up_page.dart';
import 'package:mine_storage/features/auth/sign_up/states/sign_up_state.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';

late ProviderContainer container;

Widget host(SharedPreferences prefs, {Brightness brightness = Brightness.light}) {
  container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      routerProvider.overrideWithValue(buildTestRouter()),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: const SignUpPage(),
    ),
  );
}

SignUpStateNotifier get notifier => container.read(signUpStateProvider.notifier);

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('step 1 carries the design copy and a step eyebrow', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();

    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text("We'll email you an 8-digit code to confirm it."), findsOneWidget);
    expect(find.text('Shown on your account. You can change it later.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });

  testWidgets('step 2 names the email it will be used with', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier
      ..updateEmail('maya@northsidegrocers.com')
      ..goToStep(SignUpStep.password);
    await tester.pump();

    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(find.text('Choose a password'), findsOneWidget);
    expect(
      find.text("You'll use this with maya@northsidegrocers.com to sign in."),
      findsOneWidget,
    );
    expect(find.text('At least 6 characters.'), findsOneWidget);
    expect(find.text('Create account'), findsOneWidget);
  });

  testWidgets('both password fields carry an eye, and reveal together', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier.goToStep(SignUpStep.password);
    await tester.pump();

    expect(find.byTooltip('Show password'), findsNWidgets(2));
    expect(tester.widgetList<TextField>(find.byType(TextField)).every((f) => f.obscureText), isTrue);

    await tester.tap(find.byTooltip('Show password').first);
    await tester.pump();

    expect(find.byTooltip('Hide password'), findsNWidgets(2));
    expect(tester.widgetList<TextField>(find.byType(TextField)).any((f) => f.obscureText), isFalse);
  });

  testWidgets('step 3 shows eight boxes and holds Confirm until all are filled', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier
      ..updateEmail('maya@northsidegrocers.com')
      ..goToStep(SignUpStep.code);
    await tester.pump();

    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.text('Enter your code'), findsOneWidget);
    expect(
      find.text('Sent to maya@northsidegrocers.com. It expires in 10 minutes.'),
      findsOneWidget,
    );
    expect(find.byType(OtpField), findsOneWidget);
    expect(find.text('Confirm account'), findsOneWidget);

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    notifier.updateCode('41927301');
    await tester.pump();
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });

  testWidgets('a rejected code clears the moment a digit is edited', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier
      ..updateEmail('maya@northsidegrocers.com')
      ..goToStep(SignUpStep.code)
      ..updateCode('41927301');
    await tester.pump();

    notifier.rejectCode('That code is wrong or has expired. Request a new one.');
    await tester.pump();
    expect(find.text('That code is wrong or has expired. Request a new one.'), findsOneWidget);

    notifier.updateCode('4192730');
    await tester.pump();
    expect(find.text('That code is wrong or has expired. Request a new one.'), findsNothing);
  });

  testWidgets('the resumed variant explains the skipped step', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier
      ..updateEmail('maya@northsidegrocers.com')
      ..markResumed()
      ..goToStep(SignUpStep.code);
    await tester.pump();

    expect(find.text('STEP 2 OF 2 · RESUMED'), findsOneWidget);
    expect(find.text('Finish signing up'), findsOneWidget);
    expect(find.text('You started this before. Enter the new code we just sent.'), findsOneWidget);
    expect(
      find.text('Your password is already set, so we skipped that step. '
          'The shop name you just entered replaces the old one.'),
      findsOneWidget,
    );
  });
}
