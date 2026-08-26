import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';

Decimal d(String value) => Decimal.parse(value);

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository sales;
  final today = DateTime(2026, 8, 19);

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    sales = FakeSaleRepository(products, latency: Duration.zero);
  });

  SaleDraft draft(String quantity, String price) => SaleDraft(
    lines: [
      SaleDraftLine(
        productId: 'p3',
        productName: 'Basmati rice 5kg',
        unit: ProductUnit.kg,
        quantity: d(quantity),
        unitSellPrice: d(price),
        allocations: [
          SaleAllocation(
            batchId: 'b4',
            batchCode: '#B-0001',
            quantity: d(quantity),
            unitCost: d('9.00'),
          ),
        ],
      ),
    ],
  );

  group('KpiDelta.between', () {
    test('two equal figures read flat, not zero percent up', () {
      final delta = KpiDelta.between(d('40'), d('40'));
      expect(delta.direction, DeltaDirection.flat);
      expect(delta.hasPercent, isFalse);
    });

    test('both zero reads flat', () {
      expect(KpiDelta.between(Decimal.zero, Decimal.zero).direction, DeltaDirection.flat);
    });

    test('a rise names its percentage', () {
      final delta = KpiDelta.between(d('118'), d('100'));
      expect(delta.direction, DeltaDirection.up);
      expect(delta.percent, d('18'));
      expect(delta.hasPercent, isTrue);
    });

    test('a fall names its percentage as a magnitude', () {
      final delta = KpiDelta.between(d('96'), d('100'));
      expect(delta.direction, DeltaDirection.down);
      expect(delta.percent, d('4'));
    });

    test('something against nothing rises without a percentage', () {
      final delta = KpiDelta.between(d('50'), Decimal.zero);
      expect(delta.direction, DeltaDirection.up);
      expect(delta.hasPercent, isFalse);
    });

    test('nothing against something falls by a hundred percent', () {
      final delta = KpiDelta.between(Decimal.zero, d('50'));
      expect(delta.direction, DeltaDirection.down);
      expect(delta.percent, d('100'));
    });
  });

  group('dashboardSummary', () {
    test('an empty store reports zeroes and flat deltas, never a null', () async {
      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);

      expect(summary.revenue, Decimal.zero);
      expect(summary.netProfit, Decimal.zero);
      expect(summary.salesCount, 0);
      expect(summary.avgBasket, Decimal.zero);
      expect(summary.revenueDelta.direction, DeltaDirection.flat);
      expect(summary.lastSevenDaysRevenue, Decimal.zero);
      expect(summary.lastSevenDaysSeries, hasLength(7));
    });

    test('today\'s figures come from today\'s sales', () async {
      sales.recordAt(draft('1', '20.00'), storeId: 'store-a', at: today);
      sales.recordAt(draft('1', '30.00'), storeId: 'store-a', at: today);

      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);

      expect(summary.revenue, d('50.00'));
      expect(summary.salesCount, 2);
      expect(summary.avgBasket, d('25.00'));
      expect(summary.netProfit, d('32.00'));
    });

    test('the clock time within a day does not split its bucket', () async {
      sales.recordAt(
        draft('1', '20.00'),
        storeId: 'store-a',
        at: DateTime(2026, 8, 19, 8, 30),
      );
      sales.recordAt(
        draft('1', '30.00'),
        storeId: 'store-a',
        at: DateTime(2026, 8, 19, 22, 5),
      );

      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);
      expect(summary.salesCount, 2);
      expect(summary.revenue, d('50.00'));
    });

    test('a delta compares today against yesterday', () async {
      final yesterday = today.subtract(const Duration(days: 1));
      sales.recordAt(draft('1', '100.00'), storeId: 'store-a', at: yesterday);
      sales.recordAt(draft('1', '118.00'), storeId: 'store-a', at: today);

      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);

      expect(summary.revenueDelta.direction, DeltaDirection.up);
      expect(summary.revenueDelta.percent, d('18'));
      expect(summary.salesCountDelta.direction, DeltaDirection.flat);
    });

    test('last seven days spans today back six days and excludes older sales', () async {
      sales.recordAt(draft('1', '10.00'), storeId: 'store-a', at: today);
      sales.recordAt(
        draft('1', '10.00'),
        storeId: 'store-a',
        at: today.subtract(const Duration(days: 6)),
      );
      sales.recordAt(
        draft('1', '99.00'),
        storeId: 'store-a',
        at: today.subtract(const Duration(days: 7)),
      );

      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);

      expect(summary.lastSevenDaysRevenue, d('20.00'));
      expect(summary.lastSevenDaysSeries.first, d('10.00'));
      expect(summary.lastSevenDaysSeries.last, d('10.00'));
      expect(summary.lastSevenDaysSeries[3], Decimal.zero);
    });

    test('another store\'s sales never leak into this store\'s figures', () async {
      sales.recordAt(draft('1', '75.00'), storeId: 'store-b', at: today);

      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);
      expect(summary.revenue, Decimal.zero);
      expect(summary.salesCount, 0);
    });

    test('the average basket is what buyers handed over, not net revenue', () async {
      sales.recordAt(
        SaleDraft(
          lines: draft('1', '100.00').lines,
          decimals: 2,
          fees: [
            Fee(
              id: 'vat',
              name: 'VAT 10%',
              kind: FeeKind.percent,
              value: d('10'),
              direction: FeeDirection.passThrough,
            ),
          ],
        ),
        storeId: 'store-a',
        at: today,
      );

      final summary = await sales.dashboardSummary(storeId: 'store-a', today: today);
      expect(summary.avgBasket, d('110.00'));
      expect(summary.revenue, d('100.00'));
    });
  });
}
