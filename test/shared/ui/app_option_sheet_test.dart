import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/app_option_sheet.dart';

import '../../support/localization_test_harness.dart';

const options = [
  AppOption(value: 'grocery', label: 'Tạp hóa', icon: Icons.shopping_basket_outlined),
  AppOption(value: 'cafe', label: 'Quán cà phê', icon: Icons.local_cafe_outlined),
];

Future<Future<String?>> openSheet(WidgetTester tester, {String? selected}) async {
  late Future<String?> result;

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => result = showAppOptionSheet<String>(
            context: context,
            title: 'Loại cửa hàng',
            options: options,
            selected: selected,
          ),
          child: const Text('open'),
        ),
      ),
    ),
  ));

  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
  return result;
}

void main() {
  setUp(useLocale);

  testWidgets('lists every option under its title', (tester) async {
    await openSheet(tester);

    expect(find.text('Loại cửa hàng'), findsOneWidget);
    expect(find.text('Tạp hóa'), findsOneWidget);
    expect(find.text('Quán cà phê'), findsOneWidget);
  });

  testWidgets('returns the tapped option', (tester) async {
    final result = await openSheet(tester);

    await tester.tap(find.text('Quán cà phê'));
    await tester.pumpAndSettle();

    expect(await result, 'cafe');
  });

  testWidgets('dismissing returns null', (tester) async {
    final result = await openSheet(tester);

    await tester.tapAt(const Offset(10, 10));
    await tester.pumpAndSettle();

    expect(await result, isNull);
  });

  testWidgets('exactly one option is marked as selected', (tester) async {
    await openSheet(tester, selected: 'cafe');

    expect(find.byIcon(Icons.check_rounded), findsOneWidget);
  });

  testWidgets('nothing is marked when there is no selection', (tester) async {
    await openSheet(tester);

    expect(find.byIcon(Icons.check_rounded), findsNothing);
  });
}
