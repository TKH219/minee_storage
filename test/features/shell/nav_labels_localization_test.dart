import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/app_nav_bar.dart';

import '../../support/localization_test_harness.dart';

void main() {
  Widget bar() => Theme(
    data: AppTheme.light(),
    child: Scaffold(
      bottomNavigationBar: AppNavBar(
        currentIndex: 0,
        onTap: (_) {},
        onNewSale: () {},
        destinations: AppNavBar.defaultDestinations,
      ),
    ),
  );

  testWidgets('nav labels render English by default', (tester) async {
    await pumpLocalized(tester, bar());
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Reports'), findsOneWidget);
  });

  testWidgets('nav labels translate to Vietnamese', (tester) async {
    await pumpLocalized(tester, bar(), locale: viLocale);
    expect(find.text('Tổng quan'), findsOneWidget);
    expect(find.text('Sản phẩm'), findsOneWidget);
    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.text('Báo cáo'), findsOneWidget);
  });
}
