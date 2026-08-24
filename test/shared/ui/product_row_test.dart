import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/shared/ui/expiry_badge.dart';
import 'package:mine_storage/shared/ui/product_row.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import '../../support/localization_test_harness.dart';

final today = DateTime(2026, 8, 20);

/// The row renders whatever currency the shop trades in; these expectations are
/// written against dollars, so the test names that rather than inheriting the
/// VND default.
const usd = Currency(code: 'USD', symbol: r'$', decimals: 2);

final milk = ProductEntity(
  id: 'milk',
  name: 'Whole Milk 1L',
  brand: 'Dairyland',
  createdAt: DateTime(2026, 8, 8),
  updatedAt: DateTime(2026, 8, 15),
  batches: [
    ProductBatchEntity(
      id: 'l1',
      productId: 'milk',
      storeId: 'store-a',
      batchCode: '#B-0001',
      storageLocation: 'Cold room A',
      purchasedAt: DateTime(2026, 8, 8),
      expiryDate: DateTime(2026, 8, 22),
      unitPrice: Decimal.parse('1.10'),
      initialQuantity: Decimal.fromInt(12),
      remainingQuantity: Decimal.fromInt(2),
      createdAt: DateTime(2026, 8, 8),
      updatedAt: DateTime(2026, 8, 8),
    ),
    ProductBatchEntity(
      id: 'l2',
      productId: 'milk',
      storeId: 'store-a',
      batchCode: '#B-0002',
      purchasedAt: DateTime(2026, 8, 15),
      expiryDate: DateTime(2026, 9, 12),
      unitPrice: Decimal.parse('1.25'),
      initialQuantity: Decimal.fromInt(10),
      remainingQuantity: Decimal.fromInt(8),
      createdAt: DateTime(2026, 8, 15),
      updatedAt: DateTime(2026, 8, 15),
    ),
  ],
);

Widget host(Widget child) => ProviderScope(
  overrides: [
    currencyFormatterProvider.overrideWithValue(const CurrencyFormatter(usd)),
  ],
  child: MaterialApp(
    theme: AppTheme.light(),
    home: Scaffold(body: SizedBox(width: 390, child: child)),
  ),
);

void main() {
  setUp(useLocale);

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
