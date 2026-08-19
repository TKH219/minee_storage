import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/app_buttons.dart';
import 'package:mine_storage/shared/ui/app_filter_chip.dart';
import 'package:mine_storage/shared/ui/app_text_field.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

BoxDecoration chipDecoration(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(AppFilterChip), matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  testWidgets('chip is 34 tall with a 17 radius', (tester) async {
    await tester.pumpWidget(host(const AppFilterChip(label: 'All', selected: false)));
    expect(tester.getSize(find.byType(AppFilterChip)).height, 34);
    expect(chipDecoration(tester).borderRadius, BorderRadius.circular(17));
  });

  testWidgets('a resting chip sits on neutral0 with a neutral3 border', (tester) async {
    await tester.pumpWidget(host(const AppFilterChip(label: 'All', selected: false)));
    final decoration = chipDecoration(tester);
    expect(decoration.color, const Color(0xFFFFFFFF));
    expect(decoration.border!.top.color, const Color(0xFFD8DEE4));
    expect(tester.widget<Text>(find.text('All')).style!.color, const Color(0xFF424A53));
  });

  testWidgets('selected chip takes the highlight ground, primary2 border and primary5 label',
      (tester) async {
    await tester.pumpWidget(host(const AppFilterChip(label: 'Expiring soon', selected: true)));
    final decoration = chipDecoration(tester);
    expect(decoration.color, const Color(0xFFD4F5FC));
    expect(decoration.border!.top.color, const Color(0xFFB1EDFF));
    expect(tester.widget<Text>(find.text('Expiring soon')).style!.color, const Color(0xFF08506F));
  });

  testWidgets('the optional dot is 6px and orange5', (tester) async {
    await tester.pumpWidget(host(
      const AppFilterChip(label: 'Expiring soon', selected: false, showDot: true),
    ));
    expect(tester.getSize(find.byKey(const Key('chip-dot'))), const Size(6, 6));
  });

  testWidgets('a field renders its error beneath the input', (tester) async {
    await tester.pumpWidget(host(
      const AppTextField(label: 'Email', errorText: 'Enter a complete email address.'),
    ));
    expect(find.text('Enter a complete email address.'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('Enter a complete email address.')).dy,
      greaterThan(tester.getTopLeft(find.byType(TextField)).dy),
    );
  });

  testWidgets('the field label is 12 w500 with 7px to the input', (tester) async {
    await tester.pumpWidget(host(const AppTextField(label: 'Email')));
    final label = tester.widget<Text>(find.text('Email'));
    expect(label.style!.fontSize, 12);
    expect(label.style!.fontWeight, FontWeight.w500);
    expect(
      tester.getTopLeft(find.byType(TextField)).dy - tester.getBottomLeft(find.text('Email')).dy,
      closeTo(7, 0.5),
    );
  });

  testWidgets('the tonal button uses fillPrimary with onPrimary text', (tester) async {
    await tester.pumpWidget(host(AppTonalButton(label: 'Resend code', onPressed: () {})));
    expect(find.text('Resend code'), findsOneWidget);
  });

  testWidgets('the destructive button labels in red5', (tester) async {
    await tester.pumpWidget(host(AppDestructiveButton(label: 'Archive product', onPressed: () {})));
    expect(tester.widget<Text>(find.text('Archive product')).style!.color, const Color(0xFFC93A28));
  });
}
