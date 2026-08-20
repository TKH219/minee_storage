import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/auth/forgot_password/pages/forgot_password_page.dart';
import 'package:mine_storage/features/auth/forgot_password/states/forgot_password_state.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/auth_test_harness.dart';
import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';

late ProviderContainer container;

Widget host(SharedPreferences prefs) {
  container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      sharedPreferencesProvider.overrideWithValue(prefs),
      routerProvider.overrideWithValue(buildTestRouter()),
    ],
  );
  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp(theme: AppTheme.light(), home: const ForgotPasswordPage()),
  );
}

ForgotPasswordStateNotifier get notifier =>
    container.read(forgotPasswordStateProvider.notifier);

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('step 1 asks for the address on the account', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.text('Reset your password'), findsOneWidget);
    expect(
      find.text("Enter the address on your account and we'll send a code."),
      findsOneWidget,
    );
    expect(find.text('Send code'), findsOneWidget);
  });

  testWidgets('step 2 verifies a six-digit code', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier
      ..updateEmail('maya@northsidegrocers.com')
      ..goToStep(ResetStep.code);
    await tester.pump();

    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(find.text('Enter your code'), findsOneWidget);
    expect(
      find.text('Sent to maya@northsidegrocers.com. It expires in 10 minutes.'),
      findsOneWidget,
    );
    expect(find.byType(OtpField), findsOneWidget);
    expect(find.text('Verify code'), findsOneWidget);
  });

  testWidgets('step 3 warns that saving signs the user out', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier.goToStep(ResetStep.newPassword);
    await tester.pump();

    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.text('Set a new password'), findsOneWidget);
    expect(find.text("You'll be signed out and asked to sign in with it."), findsOneWidget);
    expect(find.text('At least 6 characters.'), findsOneWidget);
    expect(find.text('Save password'), findsOneWidget);
  });

  testWidgets('both new-password fields carry an eye, and reveal together', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier.goToStep(ResetStep.newPassword);
    await tester.pump();

    expect(find.byTooltip('Show password'), findsNWidgets(2));
    expect(tester.widgetList<TextField>(find.byType(TextField)).every((f) => f.obscureText), isTrue);

    await tester.tap(find.byTooltip('Show password').last);
    await tester.pump();

    expect(find.byTooltip('Hide password'), findsNWidgets(2));
    expect(tester.widgetList<TextField>(find.byType(TextField)).any((f) => f.obscureText), isFalse);
  });

  testWidgets('a mismatched confirmation blocks saving and says so', (tester) async {
    await tester.pumpWidget(host(prefs));
    await tester.pump();
    notifier.goToStep(ResetStep.newPassword);
    await tester.pump();

    notifier
      ..updatePassword('newsecret')
      ..updateConfirmPassword('newsecrat');
    await tester.pump();

    expect(find.text("These don't match. Retype the new password."), findsOneWidget);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNull);

    notifier.updateConfirmPassword('newsecret');
    await tester.pump();

    expect(find.text("These don't match. Retype the new password."), findsNothing);
    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed, isNotNull);
  });
}
