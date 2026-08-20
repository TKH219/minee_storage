import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/otp_field.dart';

import '../../support/localization_test_harness.dart';

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SizedBox(width: 358, child: child)),
    );

BoxDecoration boxAt(WidgetTester tester, int index) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byKey(Key('otp-box-$index')),
      matching: find.byType(DecoratedBox),
    ).first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  setUp(useLocale);

  testWidgets('renders eight boxes at 54 tall with a 10 radius', (tester) async {
    await tester.pumpWidget(host(OtpField(onChanged: (_) {})));
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(Key('otp-box-$i')), findsOneWidget);
    }
    expect(tester.getSize(find.byKey(const Key('otp-box-0'))).height, 54);
    expect(boxAt(tester, 0).borderRadius, BorderRadius.circular(10));
  });

  testWidgets('code length stays eight', (tester) async {
    expect(OtpField.codeLength, 8);
  });

  testWidgets('typing reports the code and fills boxes left to right', (tester) async {
    String? seen;
    await tester.pumpWidget(host(OtpField(onChanged: (v) => seen = v)));
    await tester.enterText(find.byType(EditableText), '4192');
    await tester.pump();

    expect(seen, '4192');
    expect(find.text('4'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(boxAt(tester, 0).border!.top.color, const Color(0xFFB1EDFF));
    expect(boxAt(tester, 0).color, const Color(0xFFF0FFFF));
  });

  testWidgets('an error state borders every box in red', (tester) async {
    await tester.pumpWidget(host(OtpField(onChanged: (_) {}, hasError: true)));
    expect(boxAt(tester, 0).border!.top.color, const Color(0xFFC93A28));
    expect(boxAt(tester, 0).color, const Color(0xFFFFEDEB));
  });

  testWidgets('non-digits are rejected', (tester) async {
    String? seen;
    await tester.pumpWidget(host(OtpField(onChanged: (v) => seen = v)));
    await tester.enterText(find.byType(EditableText), '12ab34');
    await tester.pump();
    expect(seen, '1234');
  });
}
