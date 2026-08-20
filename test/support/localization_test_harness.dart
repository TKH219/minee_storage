import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Call from `setUpAll`. [EasyLocalization.ensureInitialized] reads any saved
/// locale through SharedPreferences, which has no plugin implementation under
/// flutter_test, so the mock has to be in place before it runs.
Future<void> initLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

/// `saveLocale: false` keeps a test from writing the real preference key, so a
/// Vietnamese test can never leak into the next test's default.
Widget localized(Widget child, {Locale locale = const Locale('en')}) {
  return EasyLocalization(
    supportedLocales: const [Locale('en'), Locale('vi')],
    path: 'assets/translations',
    fallbackLocale: const Locale('en'),
    startLocale: locale,
    saveLocale: false,
    child: Builder(
      builder: (context) => MaterialApp(
        localizationsDelegates: context.localizationDelegates,
        supportedLocales: context.supportedLocales,
        locale: context.locale,
        home: child,
      ),
    ),
  );
}

Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = const Locale('en'),
}) async {
  await tester.pumpWidget(localized(child, locale: locale));
  await tester.pumpAndSettle();
}
