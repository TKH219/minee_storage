import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/shared/ui/lot_card.dart';

final lotOne = Lot(
  id: 'l1',
  productId: 'milk',
  purchasedOn: DateTime(2026, 8, 8),
  expiresOn: DateTime(2026, 8, 22),
  unitPrice: 1.10,
  initialQuantity: 12,
  remainingQuantity: 2,
);

Widget host(Widget child) => MaterialApp(
      theme: AppTheme.light(),
      home: Scaffold(body: SizedBox(width: 390, child: child)),
    );

void main() {
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
    final undated = Lot(
      id: 'u1', productId: 'salt', purchasedOn: DateTime(2026, 3, 14),
      unitPrice: 2.05, initialQuantity: 21, remainingQuantity: 21,
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
