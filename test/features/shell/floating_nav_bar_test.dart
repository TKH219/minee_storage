import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/floating_nav_bar.dart';
import 'package:mine_storage/features/shell/widgets/nav_bar_item.dart';

void main() {
  Future<void> pumpBar(
    WidgetTester tester, {
    int currentIndex = 0,
    ValueChanged<int>? onDestinationSelected,
    Brightness brightness = Brightness.light,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.light
            ? AppTheme.light()
            : AppTheme.dark(),
        home: Scaffold(
          body: Center(
            child: FloatingNavBar(
              currentIndex: currentIndex,
              onDestinationSelected: onDestinationSelected ?? (_) {},
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('renders exactly three destinations', (tester) async {
    await pumpBar(tester);

    expect(find.byType(NavBarItem), findsNWidgets(3));
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
    expect(find.text('Settings'), findsOneWidget);
  });

  testWidgets('marks only the current destination as selected', (tester) async {
    await pumpBar(tester, currentIndex: 1);

    final selected = tester
        .widgetList<NavBarItem>(find.byType(NavBarItem))
        .map((item) => item.isSelected)
        .toList();

    expect(selected, [false, true, false]);
  });

  testWidgets('reports the tapped index', (tester) async {
    final taps = <int>[];
    await pumpBar(tester, onDestinationSelected: taps.add);

    await tester.tap(find.text('Settings'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Home'));
    await tester.pumpAndSettle();

    expect(taps, [2, 0]);
  });

  testWidgets('every tab meets the 48dp minimum tap target', (tester) async {
    await pumpBar(tester);

    for (var index = 0; index < kNavBarDestinations.length; index++) {
      final size = tester.getSize(find.byType(NavBarItem).at(index));
      expect(size.height, greaterThanOrEqualTo(48));
      expect(size.width, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('renders in dark mode without throwing', (tester) async {
    await pumpBar(tester, brightness: Brightness.dark, currentIndex: 2);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(NavBarItem), findsNWidgets(3));
  });
}
