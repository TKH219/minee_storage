import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/widgets/fee_row.dart';
import 'package:mine_storage/features/sales/new/widgets/fees_sheet.dart';

import '../../support/design_frame.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);

Fee fee({
  required String id,
  required String name,
  FeeKind kind = FeeKind.fixed,
  required String value,
  required FeeDirection direction,
}) {
  return Fee(
    id: id,
    name: name,
    kind: kind,
    value: d(value),
    direction: direction,
  );
}

final workedExample = [
  fee(
    id: 'promo',
    name: 'Promo 5%',
    kind: FeeKind.percent,
    value: '5',
    direction: FeeDirection.discount,
  ),
  fee(
    id: 'vat',
    name: 'VAT 8%',
    kind: FeeKind.percent,
    value: '8',
    direction: FeeDirection.passThrough,
  ),
  fee(
    id: 'delivery',
    name: 'Delivery',
    value: '2.00',
    direction: FeeDirection.buyerCharge,
  ),
  fee(
    id: 'card',
    name: 'Card fee 1.5%',
    kind: FeeKind.percent,
    value: '1.5',
    direction: FeeDirection.sellerCost,
  ),
];

void main() {
  Future<List<Fee>?> returned = Future.value();

  Future<void> pumpFees(
    WidgetTester tester, {
    List<Fee> fees = const [],
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    useDesignFrame(tester);
    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => returned = showFeesSheet(
                    context,
                    itemsSubtotal: d('35.80'),
                    fees: fees,
                    currency: usd,
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('shows a row per fee with its own tag', (tester) async {
    await pumpFees(tester, fees: workedExample);

    expect(find.byType(FeeRow), findsNWidgets(4));
    expect(find.text('DISCOUNT'), findsOneWidget);
    expect(find.text('PASS-THROUGH'), findsOneWidget);
    expect(find.text('BUYER'), findsOneWidget);
    expect(find.text('YOUR COST'), findsOneWidget);
  });

  testWidgets('signs each amount by which way it moves the money',
      (tester) async {
    await pumpFees(tester, fees: workedExample);

    expect(
      tester.widget<Text>(find.byKey(const Key('fee-amount-promo'))).data,
      '−\$1.79',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('fee-amount-vat'))).data,
      '+\$2.72',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('fee-amount-delivery'))).data,
      '+\$2.00',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('fee-amount-card'))).data,
      '−\$0.51',
    );
  });

  testWidgets('every row names the base its amount came from', (tester) async {
    await pumpFees(tester, fees: workedExample);

    expect(find.text('on items subtotal'), findsOneWidget);
    expect(find.text('fixed, you keep it'), findsOneWidget);
    // Both percent fees are charged on the same post-discount base — that is
    // the rule, and the row says so on each of them.
    expect(find.text(r'on $34.01 after discount'), findsNWidgets(2));
  });

  testWidgets('without a discount a percent fee names the plain subtotal',
      (tester) async {
    await pumpFees(tester, fees: [workedExample[1]]);

    expect(find.text(r'on $35.80'), findsOneWidget);
    expect(find.textContaining('after discount'), findsNothing);
  });

  testWidgets('says outright that discounts apply first', (tester) async {
    await pumpFees(tester, fees: workedExample);

    expect(
      find.textContaining('Discounts apply first'),
      findsOneWidget,
    );
  });

  testWidgets('removing a fee drops its row', (tester) async {
    await pumpFees(tester, fees: workedExample);

    await tester.tap(find.byKey(const Key('fee-remove-delivery')));
    await tester.pumpAndSettle();

    expect(find.byType(FeeRow), findsNWidgets(3));
    expect(find.text('Delivery'), findsNothing);
  });

  testWidgets('Done hands the edited list back', (tester) async {
    await pumpFees(tester, fees: workedExample);

    await tester.tap(find.byKey(const Key('fee-remove-card')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fees-done')));
    await tester.pumpAndSettle();

    final fees = await returned;
    expect(fees, hasLength(3));
    expect(fees!.map((each) => each.id), isNot(contains('card')));
  });

  testWidgets('an empty list says so rather than showing nothing',
      (tester) async {
    await pumpFees(tester);

    expect(find.text('No fees or discounts yet.'), findsOneWidget);
    expect(find.byType(FeeRow), findsNothing);
  });

  testWidgets('adding a fee needs a name and a value', (tester) async {
    await pumpFees(tester);

    await tester.tap(find.byKey(const Key('fees-add')));
    await tester.pumpAndSettle();

    final blank = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('add-fee-confirm')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(blank.onPressed, isNull);

    await tester.enterText(find.byKey(const Key('add-fee-name')), 'Tip');
    await tester.enterText(find.byKey(const Key('add-fee-value')), '3.00');
    await tester.pumpAndSettle();

    final filled = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('add-fee-confirm')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(filled.onPressed, isNotNull);

    await tester.tap(find.byKey(const Key('add-fee-confirm')));
    await tester.pumpAndSettle();

    expect(find.text('Tip'), findsOneWidget);
    expect(find.byType(FeeRow), findsOneWidget);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpFees(tester, fees: workedExample, locale: viLocale);

    expect(find.text('Phí & giảm giá'), findsOneWidget);
    expect(find.text('GIẢM GIÁ'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpFees(tester, fees: workedExample, brightness: Brightness.dark);

    expect(find.text('Fees & discounts'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
