import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/expiry_status.dart';
import 'package:mine_storage/shared/ui/expiry_badge.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: Center(child: child)),
    );

BoxDecoration decorationOf(WidgetTester tester) {
  final box = tester.widget<DecoratedBox>(
    find.descendant(of: find.byType(ExpiryBadge), matching: find.byType(DecoratedBox)).first,
  );
  return box.decoration as BoxDecoration;
}

void main() {
  final today = DateTime(2026, 8, 20);

  testWidgets('expiring soon uses the orange tint pair', (tester) async {
    await tester.pumpWidget(host(
      ExpiryBadge(status: ExpiryStatus.expiringSoon, expiry: DateTime(2026, 9, 12), today: today),
    ));
    expect(decorationOf(tester).color, const Color(0xFFFFF3E4));
    expect(tester.widget<Text>(find.byType(Text)).style!.color, const Color(0xFFA85506));
  });

  testWidgets('expired uses the red tint pair', (tester) async {
    await tester.pumpWidget(host(
      ExpiryBadge(status: ExpiryStatus.expired, expiry: DateTime(2026, 8, 14), today: today),
    ));
    expect(decorationOf(tester).color, const Color(0xFFFFEDEB));
    expect(tester.widget<Text>(find.byType(Text)).style!.color, const Color(0xFFC93A28));
  });

  testWidgets('healthy is bare text, not a pill', (tester) async {
    await tester.pumpWidget(host(
      ExpiryBadge(status: ExpiryStatus.healthy, expiry: DateTime(2026, 11, 3), today: today),
    ));
    expect(decorationOf(tester).color, Colors.transparent);
    expect(tester.widget<Text>(find.byType(Text)).style!.fontSize, 12);
    expect(tester.widget<Text>(find.byType(Text)).style!.fontWeight, FontWeight.w400);
    expect(find.text('3 Nov 2026'), findsOneWidget);
  });

  testWidgets('no stock reads "No stock"', (tester) async {
    await tester.pumpWidget(host(const ExpiryBadge(status: ExpiryStatus.none)));
    expect(find.text('No stock'), findsOneWidget);
  });

  testWidgets('archived overrides the status label', (tester) async {
    await tester.pumpWidget(host(
      const ExpiryBadge(status: ExpiryStatus.none, archived: true),
    ));
    expect(find.text('Archived'), findsOneWidget);
  });

  testWidgets('a pill badge is 22 tall with 11px semibold text', (tester) async {
    await tester.pumpWidget(host(
      ExpiryBadge(status: ExpiryStatus.expired, expiry: DateTime(2026, 8, 14), today: today),
    ));
    expect(tester.getSize(find.byType(ExpiryBadge)).height, 22);
    final text = tester.widget<Text>(find.byType(Text));
    expect(text.style!.fontSize, 11);
    expect(text.style!.fontWeight, FontWeight.w600);
  });

  testWidgets('expiring soon shows the day countdown', (tester) async {
    await tester.pumpWidget(host(
      ExpiryBadge(status: ExpiryStatus.expiringSoon, expiry: DateTime(2026, 9, 13), today: today),
    ));
    expect(find.text('13 Sep · 24d'), findsOneWidget);
  });

  testWidgets('dark mode takes the dark tint, not an inverted light one', (tester) async {
    await tester.pumpWidget(host(
      ExpiryBadge(status: ExpiryStatus.expiringSoon, expiry: DateTime(2026, 9, 12), today: today),
      brightness: Brightness.dark,
    ));
    expect(decorationOf(tester).color, const Color(0xFF3A2A14));
  });
}
