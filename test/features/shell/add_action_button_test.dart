import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/add_action_button.dart';

void main() {
  Future<void> pumpButton(WidgetTester tester, VoidCallback onPressed) {
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(child: AddActionButton(onPressed: onPressed)),
        ),
      ),
    );
  }

  testWidgets('renders an add glyph', (tester) async {
    await pumpButton(tester, () {});

    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
  });

  testWidgets('invokes its callback once per tap', (tester) async {
    var taps = 0;
    await pumpButton(tester, () => taps++);

    await tester.tap(find.byType(AddActionButton));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });

  testWidgets('meets the 48dp minimum tap target', (tester) async {
    await pumpButton(tester, () {});

    final size = tester.getSize(find.byType(AddActionButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
  });
}
