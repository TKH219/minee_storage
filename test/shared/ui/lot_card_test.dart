import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/shared/ui/lot_card.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';

import '../../support/localization_test_harness.dart';

/// The card renders whatever currency the shop trades in; these expectations
/// are written against dollars, so the test names that rather than inheriting
/// the VND default.
const usd = Currency(code: 'USD', symbol: r'$', decimals: 2);

final lotOne = ProductBatchEntity(
  id: 'l1',
  productId: 'milk',
  storeId: 'store-a',
  batchCode: '#B-0001',
  purchasedAt: DateTime(2026, 8, 8),
  expiryDate: DateTime(2026, 8, 22),
  unitPrice: Decimal.parse('1.10'),
  initialQuantity: Decimal.fromInt(12),
  remainingQuantity: Decimal.fromInt(2),
  createdAt: DateTime(2026, 8, 8),
  updatedAt: DateTime(2026, 8, 8),
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

  testWidgets('lot total is price times initial, computed not stored', (tester) async {
    await tester.pumpWidget(host(LotCard(lot: lotOne, today: DateTime(2026, 8, 20))));
    expect(find.text(r'$13.20'), findsOneWidget);
    expect(find.text('2.000'), findsOneWidget);
    expect(find.textContaining('of 12.000'), findsOneWidget);
  });

  testWidgets('the next-out lot carries the marker', (tester) async {
    await tester.pumpWidget(host(
      LotCard(lot: lotOne, isNextOut: true, today: DateTime(2026, 8, 20)),
    ));
    expect(find.text('NEXT OUT'), findsOneWidget);
  });

  testWidgets('a lot without a marker does not show one', (tester) async {
    await tester.pumpWidget(host(LotCard(lot: lotOne, today: DateTime(2026, 8, 20))));
    expect(find.text('NEXT OUT'), findsNothing);
  });

  testWidgets('an undated lot reads "Not tracked" rather than a dash', (tester) async {
    final undated = ProductBatchEntity(
      id: 'u1',
      productId: 'salt',
      storeId: 'store-a',
      batchCode: '#B-0001',
      purchasedAt: DateTime(2026, 3, 14),
      unitPrice: Decimal.parse('2.05'),
      initialQuantity: Decimal.fromInt(21),
      remainingQuantity: Decimal.fromInt(21),
      createdAt: DateTime(2026, 3, 14),
      updatedAt: DateTime(2026, 3, 14),
    );
    await tester.pumpWidget(host(LotCard(lot: undated, today: DateTime(2026, 8, 20))));
    expect(find.text('Not tracked'), findsOneWidget);
  });

  testWidgets('the card uses the 12 radius from the design', (tester) async {
    await tester.pumpWidget(host(LotCard(lot: lotOne, today: DateTime(2026, 8, 20))));
    final box = tester.widget<Container>(find.byKey(const Key('lot-card-container')));
    final decoration = box.decoration! as BoxDecoration;
    expect(decoration.borderRadius, BorderRadius.circular(12));
  });
}
