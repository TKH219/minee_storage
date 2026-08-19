import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/domain/entities/product.dart';
import 'package:mine_storage/shared/ui/expiry_badge.dart';
import 'package:mine_storage/shared/ui/product_row.dart';

final today = DateTime(2026, 8, 20);

final milk = Product(
  id: 'milk',
  storeId: 's1',
  name: 'Whole Milk 1L',
  brand: 'Dairyland',
  location: 'Cold room A',
  lots: [
    Lot(id: 'l1', productId: 'milk', purchasedOn: DateTime(2026, 8, 8),
        expiresOn: DateTime(2026, 8, 22), unitPrice: 1.10, initialQuantity: 12, remainingQuantity: 2),
    Lot(id: 'l2', productId: 'milk', purchasedOn: DateTime(2026, 8, 15),
        expiresOn: DateTime(2026, 9, 12), unitPrice: 1.25, initialQuantity: 10, remainingQuantity: 8),
  ],
);

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SizedBox(width: 390, child: child)),
    );

void main() {
  testWidgets('row answers the four questions at a glance', (tester) async {
    await tester.pumpWidget(host(ProductRow(product: milk, today: today)));
    expect(find.text('Whole Milk 1L'), findsOneWidget);
    expect(find.text(r'$1.25'), findsOneWidget);
    expect(find.text('10.000'), findsOneWidget);
    expect(find.byType(ExpiryBadge), findsOneWidget);
  });

  testWidgets('quantities render to exactly three decimals', (tester) async {
    await tester.pumpWidget(host(ProductRow(product: milk, today: today)));
    expect(find.text('10.000'), findsOneWidget);
    expect(find.text('10.0'), findsNothing);
  });

  testWidgets('brand and location join the sub line', (tester) async {
    await tester.pumpWidget(host(ProductRow(product: milk, today: today)));
    expect(find.textContaining('Dairyland'), findsOneWidget);
    expect(find.textContaining('Cold room A'), findsOneWidget);
  });

  testWidgets('thumbnail is 56 square and row padding is 12/16', (tester) async {
    await tester.pumpWidget(host(ProductRow(product: milk, today: today)));
    expect(tester.getSize(find.byKey(const Key('product-row-thumb'))), const Size(56, 56));
    final padding = tester.widget<Padding>(find.byKey(const Key('product-row-padding')));
    expect(padding.padding, const EdgeInsets.symmetric(vertical: 12, horizontal: 16));
  });

  testWidgets('tapping the row reports it', (tester) async {
    var taps = 0;
    await tester.pumpWidget(host(ProductRow(product: milk, today: today, onTap: () => taps++)));
    await tester.tap(find.byType(ProductRow));
    expect(taps, 1);
  });
}
