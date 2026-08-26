import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// A translation key that escaped to the screen: `group.someKey`, with no
/// spaces and at least one dot between lowerCamel segments.
final RegExp rawKeyPattern = RegExp(r'^[a-z][a-zA-Z0-9]*(\.[a-zA-Z0-9]+)+$');

/// Fails when any rendered `Text` is a raw key rather than a translation.
///
/// The one thing every localised screen has to get right, and the one that is
/// easy to miss: a missing key renders as its own path and looks like copy.
void expectNoRawKeys(WidgetTester tester) {
  final leaked = <String>[];

  for (final text in tester.widgetList<Text>(find.byType(Text))) {
    final data = text.data;
    if (data == null) continue;
    if (rawKeyPattern.hasMatch(data.trim())) leaked.add(data);
  }

  expect(leaked, isEmpty, reason: 'these rendered as raw translation keys');
}
