import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Locale enLocale = Locale('en');
const Locale viLocale = Locale('vi');

/// Installs a locale's real translation file into easy_localization's
/// singleton, which is what `String.tr()` reads.
///
/// Deliberately does not use the `EasyLocalization` widget: that loads
/// translations through `rootBundle`, and `pumpAndSettle` only advances a fake
/// clock, so the asset future never completes for any test after the first one
/// in a file. Reading the file off disk keeps it synchronous and leaves no
/// state to leak between tests.
void useLocale([Locale locale = enLocale]) {
  final raw = File('assets/translations/${locale.languageCode}.json').readAsStringSync();
  Localization.load(
    locale,
    translations: Translations(jsonDecode(raw) as Map<String, dynamic>),
  );
}

/// Wraps [child] in a bare `MaterialApp` with a locale already installed.
Widget localized(Widget child, {Locale locale = enLocale}) {
  useLocale(locale);
  return MaterialApp(home: child);
}

Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = enLocale,
}) async {
  await tester.pumpWidget(localized(child, locale: locale));
  await tester.pumpAndSettle();
}
