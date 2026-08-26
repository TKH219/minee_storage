import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

Decimal d(String value) => Decimal.parse(value);

SaleAllocation alloc(
  String batchId,
  String quantity,
  String cost, {
  String? remainingAfter,
}) {
  return SaleAllocation(
    batchId: batchId,
    batchCode: '#B-0001',
    quantity: d(quantity),
    unitCost: d(cost),
    remainingAfter: remainingAfter == null ? null : d(remainingAfter),
  );
}

void main() {
  final milk = SaleDraftLine(
    productId: 'p2',
    productName: 'Whole Milk 1L',
    unit: ProductUnit.litre,
    quantity: d('6'),
    unitSellPrice: d('1.80'),
    allocations: [
      alloc('b1', '2', '1.10', remainingAfter: '0'),
      alloc('b2', '4', '1.25', remainingAfter: '4'),
    ],
  );

  final rice = SaleDraftLine(
    productId: 'p3',
    productName: 'Basmati Rice 5kg',
    unit: ProductUnit.kg,
    quantity: d('2'),
    unitSellPrice: d('12.50'),
    allocations: [alloc('b4', '2', '8.90', remainingAfter: '6')],
  );

  group('SaleAllocation', () {
    test('costs the quantity it draws at that lot\'s own cost', () {
      expect(alloc('b1', '2', '1.10').cost, d('2.20'));
    });

    test('knows when it empties the lot it draws from', () {
      expect(alloc('b1', '2', '1.10', remainingAfter: '0').emptiesLot, isTrue);
      expect(alloc('b2', '4', '1.25', remainingAfter: '4').emptiesLot, isFalse);
    });

    test('does not claim to empty a lot whose remainder is unknown', () {
      expect(alloc('b1', '2', '1.10').emptiesLot, isFalse);
    });
  });

  group('SaleDraftLine', () {
    test('a line total is quantity times sell price', () {
      expect(milk.lineTotal, d('10.80'));
      expect(rice.lineTotal, d('25.00'));
    });

    test('a line cost is each lot at its own cost, never an average', () {
      expect(milk.lineCost, d('7.20'));
      expect(rice.lineCost, d('17.80'));
    });

    test('a line drawn from more than one lot reports itself as split', () {
      expect(milk.isSplit, isTrue);
      expect(milk.allocations.length, 2);
      expect(rice.isSplit, isFalse);
    });
  });

  group('SaleDraft', () {
    test('rolls its lines up into the section 5.3 totals', () {
      final draft = SaleDraft(
        lines: [milk, rice],
        decimals: 2,
        fees: [
          Fee(
            id: 'f1',
            name: 'Promo 5%',
            kind: FeeKind.percent,
            value: d('5'),
            direction: FeeDirection.discount,
          ),
          Fee(
            id: 'f2',
            name: 'VAT 8%',
            kind: FeeKind.percent,
            value: d('8'),
            direction: FeeDirection.passThrough,
          ),
          Fee(
            id: 'f3',
            name: 'Delivery',
            kind: FeeKind.fixed,
            value: d('2.00'),
            direction: FeeDirection.buyerCharge,
          ),
          Fee(
            id: 'f4',
            name: 'Card fee 1.5%',
            kind: FeeKind.percent,
            value: d('1.5'),
            direction: FeeDirection.sellerCost,
          ),
        ],
      );

      expect(draft.itemsSubtotal, d('35.80'));
      expect(draft.cogs, d('25.00'));
      expect(draft.totals.buyerTotal, d('38.73'));
      expect(draft.totals.netRevenue, d('35.50'));
      expect(draft.totals.netProfit, d('10.50'));
      expect(draft.totals.feesAndDiscounts, d('2.93'));
    });

    test('counts the distinct lots it will draw from', () {
      final draft = SaleDraft(lines: [milk, rice]);
      expect(draft.lotCount, 3);
    });

    test('counts a lot drawn by two lines only once', () {
      final other = milk.copyWith(allocations: [alloc('b1', '1', '1.10')]);
      final draft = SaleDraft(lines: [milk, other]);
      expect(draft.lotCount, 2);
    });

    test('an empty draft totals to zero rather than throwing', () {
      const draft = SaleDraft();
      expect(draft.isEmpty, isTrue);
      expect(draft.itemsSubtotal, Decimal.zero);
      expect(draft.cogs, Decimal.zero);
      expect(draft.totals.buyerTotal, Decimal.zero);
      expect(draft.lotCount, 0);
    });

    test('copyWith replaces only what it is given', () {
      final draft = SaleDraft(lines: [milk], decimals: 2);
      final vnd = draft.copyWith(decimals: 0);
      expect(vnd.decimals, 0);
      expect(vnd.lines, draft.lines);
      expect(vnd.paymentMethod, PaymentMethod.cash);
    });

    test('the draft\'s decimals drive the rounding its totals use', () {
      final line = SaleDraftLine(
        productId: 'p9',
        productName: 'Rice',
        unit: ProductUnit.kg,
        quantity: d('1'),
        unitSellPrice: d('10005'),
        allocations: [alloc('b9', '1', '5000')],
      );
      final vnd = SaleDraft(
        lines: [line],
        decimals: 0,
        fees: [
          Fee(
            id: 'f',
            name: 'VAT 8%',
            kind: FeeKind.percent,
            value: d('8'),
            direction: FeeDirection.passThrough,
          ),
        ],
      );
      expect(vnd.totals.fees.single.amount, d('800'));
    });
  });

  group('Sale', () {
    test('a paid line keeps the figures it was confirmed with', () {
      final sale = Sale(
        id: 'sale-1042',
        code: '#1042',
        storeId: 'store-a',
        paidAt: DateTime(2026, 8, 19),
        paymentMethod: PaymentMethod.cash,
        deductedLotCount: 3,
        totals: SaleTotals.zero,
        lines: [
          SaleLine(
            productId: 'p2',
            productName: 'Whole Milk 1L',
            quantity: d('6'),
            unitSellPrice: d('1.80'),
            allocations: milk.allocations,
          ),
        ],
      );

      expect(sale.lines.single.lineTotal, d('10.80'));
      expect(sale.lines.single.lineCost, d('7.20'));
      expect(sale.deductedLotCount, 3);
    });
  });
}
