import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'localization_test_harness.dart';

void main() {
  testWidgets('renders English by default', (tester) async {
    await pumpLocalized(tester, Builder(builder: (_) => Text(LocaleKeys.common_tryAgain.tr())));
    expect(find.text('Try again'), findsOneWidget);
  });

  testWidgets('renders Vietnamese when asked', (tester) async {
    await pumpLocalized(
      tester,
      Builder(builder: (_) => Text(LocaleKeys.common_tryAgain.tr())),
      locale: viLocale,
    );
    expect(find.text('Thử lại'), findsOneWidget);
  });

  testWidgets('a Vietnamese test does not leak into the next test', (tester) async {
    await pumpLocalized(tester, Builder(builder: (_) => Text(LocaleKeys.common_tryAgain.tr())));
    expect(find.text('Try again'), findsOneWidget);
  });
}
