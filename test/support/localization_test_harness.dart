import 'dart:convert';
import 'dart:io';

// ignore: implementation_imports
import 'package:easy_localization/src/localization.dart';
// ignore: implementation_imports
import 'package:easy_localization/src/translations.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
/// Gives [EasyLocalization]'s controller its preference storage. Without it the
/// controller's translation load fails silently and every key renders as its
/// own path.
Future<void> initLocalization() async {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
}

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

/// Set [settle] to false for screens carrying an indefinite animation — the
/// splash spinner never stops, so `pumpAndSettle` would time out on it.
Future<void> pumpLocalized(
  WidgetTester tester,
  Widget child, {
  Locale locale = enLocale,
  bool settle = true,
}) async {
  await tester.pumpWidget(localized(child, locale: locale));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }
}

/// Loads translations straight off disk, synchronously.
///
/// The default [RootBundleAssetLoader] returns a real async future, and
/// `pumpAndSettle` only advances a fake clock — so an `EasyLocalization` widget
/// under test would never finish loading. Returning a [SynchronousFuture] makes
/// the widget usable in widget tests.
class FileAssetLoader extends AssetLoader {
  const FileAssetLoader();

  @override
  Future<Map<String, dynamic>?> load(String path, Locale locale) {
    final raw = File('$path/${locale.languageCode}.json').readAsStringSync();
    return SynchronousFuture<Map<String, dynamic>?>(
      jsonDecode(raw) as Map<String, dynamic>,
    );
  }
}

/// A real [EasyLocalization] ancestor, for screens that call `context.locale`
/// or `context.setLocale` and cannot work off the singleton alone.
Widget localizedApp(Widget child, {Locale locale = enLocale}) {
  return EasyLocalization(
    supportedLocales: const [enLocale, viLocale],
    path: 'assets/translations',
    fallbackLocale: enLocale,
    startLocale: locale,
    saveLocale: false,
    assetLoader: const FileAssetLoader(),
    child: Builder(
      builder: (context) {
        // easy_localization's own delegate is deliberately left out: under
        // flutter_test its async load resolves with nothing and overwrites the
        // singleton that `tr()` reads. Seeding from `context.locale` on every
        // build keeps the two in step, including after `setLocale`.
        return MaterialApp(
          localizationsDelegates: context.localizationDelegates,
          locale: context.locale,
          supportedLocales: context.supportedLocales,
          // Seeded here, below Localizations, rather than above MaterialApp:
          // easy_localization's delegate reloads asynchronously on a locale
          // change and lands a null translation set on the singleton, so a seed
          // placed higher would be overwritten before the screen rebuilds.
          home: Builder(
            builder: (inner) {
              useLocale(Localizations.localeOf(inner));
              return child;
            },
          ),
        );
      },
    ),
  );
}

/// Set [settle] false for a screen carrying an indefinite animation — the scan
/// sweep never stops, so `pumpAndSettle` would time out on it.
Future<void> pumpLocalizedApp(
  WidgetTester tester,
  Widget child, {
  Locale locale = enLocale,
  bool settle = true,
}) async {
  // Without this the controller has no storage, its load fails silently, and
  // every key renders as its own path.
  await initLocalization();
  await tester.pumpWidget(localizedApp(child, locale: locale));
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    await tester.pump();
  }

  // `EasyLocalizationController._savedLocale` is static, so a locale chosen by
  // an earlier test in the same file can outlive it and beat `startLocale`.
  // Force the locale we were actually asked for.
  final context = tester.element(find.byType(MaterialApp));
  if (context.locale != locale) {
    await context.setLocale(locale);
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
  }
}
