import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/sales/pages/sales_list_page.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';

import '../../support/design_frame.dart';
import '../../support/localization_test_harness.dart';

/// S25 (transaction list) and S26 (transaction detail) are not drawn anywhere
/// in the design. The tab therefore ships as a deliberate stub, and these
/// tests pin it to that — not to an invented layout.
void main() {
  Future<void> pumpSalesTab(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    useDesignFrame(tester);
    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      MaterialApp(
        theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        home: const SalesListPage(),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('reads as deliberate rather than broken', (tester) async {
    await pumpSalesTab(tester);

    expect(find.text('Sales'), findsOneWidget);
    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('No sales yet'), findsOneWidget);
  });

  testWidgets('does not promise a history it cannot show', (tester) async {
    await pumpSalesTab(tester);

    // Sales are recordable now, but nothing lists them — copy claiming they
    // "will appear here" would be a promise the app does not keep.
    expect(find.textContaining('will appear here'), findsNothing);
    expect(find.textContaining('not built yet'), findsOneWidget);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpSalesTab(tester, locale: viLocale);

    expect(find.text('Bán hàng'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpSalesTab(tester, brightness: Brightness.dark);

    expect(find.text('Sales'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
