import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/app_nav_bar.dart';
import 'package:mine_storage/features/shell/widgets/nav_bar_item.dart';
import 'package:mine_storage/features/shell/widgets/new_sale_action.dart';

Widget host(Widget child, {Brightness brightness = Brightness.light}) => MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: Scaffold(body: Align(alignment: Alignment.bottomCenter, child: SizedBox(width: 390, child: child))),
    );

Widget navBar({
  int currentIndex = 3,
  ValueChanged<int>? onTap,
  VoidCallback? onNewSale,
}) =>
    AppNavBar(
      currentIndex: currentIndex,
      onTap: onTap ?? (_) {},
      onNewSale: onNewSale ?? () {},
      destinations: AppNavBar.defaultDestinations,
    );

void main() {
  testWidgets('the bar is 88 tall, full width and square-cornered', (tester) async {
    await tester.pumpWidget(host(navBar()));
    expect(tester.getSize(find.byType(AppNavBar)), const Size(390, 88));
  });

  testWidgets('five slots: four tabs plus the centre action', (tester) async {
    await tester.pumpWidget(host(navBar()));
    expect(find.byType(NavBarItem), findsNWidgets(4));
    expect(find.byType(NewSaleAction), findsOneWidget);
    for (final label in ['Dashboard', 'Products', 'New sale', 'Sales', 'Reports']) {
      expect(find.text(label), findsOneWidget, reason: label);
    }
  });

  testWidgets('selection is colour only, with no highlight pill behind it', (tester) async {
    await tester.pumpWidget(host(navBar(currentIndex: 0)));
    final label = tester.widget<Text>(find.text('Dashboard'));
    expect(label.style!.color, const Color(0xFF0F72B0));
    expect(label.style!.fontWeight, FontWeight.w600);
    expect(find.byKey(const Key('nav-highlight')), findsNothing);
  });

  testWidgets('an unselected tab is neutral6 at regular weight', (tester) async {
    await tester.pumpWidget(host(navBar(currentIndex: 0)));
    final label = tester.widget<Text>(find.text('Products'));
    expect(label.style!.color, const Color(0xFF6E7781));
    expect(label.style!.fontWeight, isNot(FontWeight.w600));
  });

  testWidgets('tab labels are 11px with the design tracking', (tester) async {
    await tester.pumpWidget(host(navBar()));
    final label = tester.widget<Text>(find.text('Products'));
    expect(label.style!.fontSize, 11);
    expect(label.style!.letterSpacing, closeTo(0.11, 0.001));
  });

  testWidgets('the centre action is 56 square and never selected', (tester) async {
    var newSaleTaps = 0;
    await tester.pumpWidget(host(navBar(currentIndex: 0, onNewSale: () => newSaleTaps++)));
    expect(tester.getSize(find.byKey(const Key('new-sale-circle'))), const Size(56, 56));
    await tester.tap(find.byKey(const Key('new-sale-circle')));
    expect(newSaleTaps, 1);
  });

  testWidgets('tapping a tab reports its index, skipping the action slot', (tester) async {
    final taps = <int>[];
    await tester.pumpWidget(host(navBar(onTap: taps.add)));
    await tester.tap(find.text('Sales'));
    expect(taps, [2]);
    await tester.tap(find.text('Dashboard'));
    expect(taps, [2, 0]);
  });

  testWidgets('the bar sits on barSurface with a hairline top border', (tester) async {
    await tester.pumpWidget(host(navBar()));
    final decorated = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(AppNavBar), matching: find.byType(DecoratedBox)).first,
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFFFFFFFF));
    expect(decoration.border!.top.color, const Color(0xFFEAEEF2));
    expect(decoration.border!.top.width, 1);
    expect(decoration.borderRadius, isNull);
  });

  testWidgets('dark mode takes the dark bar surface and border', (tester) async {
    await tester.pumpWidget(host(navBar(), brightness: Brightness.dark));
    final decorated = tester.widget<DecoratedBox>(
      find.descendant(of: find.byType(AppNavBar), matching: find.byType(DecoratedBox)).first,
    );
    final decoration = decorated.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xFF1E252E));
    expect(decoration.border!.top.color, const Color(0xFF2A313C));
  });

  testWidgets('items are top-aligned 9px into the bar, not centred in it', (tester) async {
    await tester.pumpWidget(host(navBar()));
    final barTop = tester.getTopLeft(find.byType(AppNavBar)).dy;
    final iconTop = tester.getTopLeft(find.byIcon(Icons.inventory_2_outlined)).dy;
    expect(iconTop - barTop, closeTo(9, 0.5));
  });

  testWidgets('the bar leaves room below the labels for the home indicator', (tester) async {
    await tester.pumpWidget(host(navBar()));
    final barBottom = tester.getBottomLeft(find.byType(AppNavBar)).dy;
    final labelBottom = tester.getBottomLeft(find.text('Products')).dy;
    expect(barBottom - labelBottom, greaterThan(20));
  });
}
