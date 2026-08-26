import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/services/sale_money.dart';

Decimal d(String value) => Decimal.parse(value);

void main() {
  group('SaleMoney.compute', () {
    test('reproduces every figure the design works through on S22 and S23', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('35.80'),
        cogs: d('25.00'),
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

      expect(totals.itemsSubtotal, d('35.80'));
      expect(totals.discountTotal, d('1.79'));
      expect(totals.fees[1].base, d('34.01'));
      expect(totals.fees[1].amount, d('2.72'));
      expect(totals.fees[2].amount, d('2.00'));
      expect(totals.fees[3].amount, d('0.51'));
      expect(totals.buyerChargeTotal, d('4.72'));
      expect(totals.buyerTotal, d('38.73'));
      expect(totals.passThroughTotal, d('2.72'));
      expect(totals.sellerCostTotal, d('0.51'));
      expect(totals.lessPassThroughAndCosts, d('3.23'));
      expect(totals.netRevenue, d('35.50'));
      expect(totals.cogs, d('25.00'));
      expect(totals.netProfit, d('10.50'));
      expect((totals.netMargin * d('100')).round(scale: 1), d('29.6'));
      expect(totals.feesAndDiscounts, d('2.93'));
    });

    test('a fixed discount comes off before a percent fee is charged', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('100.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'a',
            name: 'Ten off',
            kind: FeeKind.fixed,
            value: d('10.00'),
            direction: FeeDirection.discount,
          ),
          Fee(
            id: 'b',
            name: 'VAT 10%',
            kind: FeeKind.percent,
            value: d('10'),
            direction: FeeDirection.passThrough,
          ),
        ],
      );

      expect(totals.fees[1].amount, d('9.00'));
      expect(totals.buyerTotal, d('99.00'));
    });

    test('a percent fee names the base it was charged on', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('50.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'a',
            name: 'VAT 10%',
            kind: FeeKind.percent,
            value: d('10'),
            direction: FeeDirection.passThrough,
          ),
        ],
      );

      expect(totals.fees.single.base, d('50.00'));
    });

    test('a fixed fee names no base, because there is nothing to name', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('50.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'a',
            name: 'Delivery',
            kind: FeeKind.fixed,
            value: d('2.00'),
            direction: FeeDirection.buyerCharge,
          ),
        ],
      );

      expect(totals.fees.single.base, isNull);
    });

    test('percent fees round half-up to the currency precision, and VND takes none', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('10005'),
        cogs: Decimal.zero,
        decimals: 0,
        fees: [
          Fee(
            id: 'a',
            name: 'VAT 8%',
            kind: FeeKind.percent,
            value: d('8'),
            direction: FeeDirection.passThrough,
          ),
        ],
      );

      expect(totals.fees.single.amount, d('800'));
      expect(totals.buyerTotal, d('10805'));
    });

    test('net margin is zero when net revenue is zero, rather than dividing by it', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: Decimal.zero,
        cogs: Decimal.zero,
        decimals: 2,
        fees: const [],
      );

      expect(totals.netMargin, Decimal.zero);
      expect(totals.buyerTotal, Decimal.zero);
    });

    test('a seller cost never changes what the buyer hands over', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('50.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'a',
            name: 'Gateway',
            kind: FeeKind.fixed,
            value: d('1.50'),
            direction: FeeDirection.sellerCost,
          ),
        ],
      );

      expect(totals.buyerTotal, d('50.00'));
      expect(totals.netRevenue, d('48.50'));
    });

    test('a pass-through fee raises the buyer total but not what the store keeps', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('50.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'a',
            name: 'VAT',
            kind: FeeKind.fixed,
            value: d('5.00'),
            direction: FeeDirection.passThrough,
          ),
        ],
      );

      expect(totals.buyerTotal, d('55.00'));
      expect(totals.netRevenue, d('50.00'));
    });

    test('a buyer charge the store keeps raises both', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('50.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'a',
            name: 'Delivery',
            kind: FeeKind.fixed,
            value: d('5.00'),
            direction: FeeDirection.buyerCharge,
          ),
        ],
      );

      expect(totals.buyerTotal, d('55.00'));
      expect(totals.netRevenue, d('55.00'));
    });

    test('the order fees are listed in does not change any amount', () {
      List<Fee> fees(bool discountFirst) {
        final discount = Fee(
          id: 'a',
          name: 'Promo',
          kind: FeeKind.percent,
          value: d('10'),
          direction: FeeDirection.discount,
        );
        final vat = Fee(
          id: 'b',
          name: 'VAT',
          kind: FeeKind.percent,
          value: d('10'),
          direction: FeeDirection.passThrough,
        );
        return discountFirst ? [discount, vat] : [vat, discount];
      }

      Decimal buyerTotalFor(bool discountFirst) => SaleMoney.compute(
        itemsSubtotal: d('100.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: fees(discountFirst),
      ).buyerTotal;

      expect(buyerTotalFor(true), d('99.00'));
      expect(buyerTotalFor(false), d('99.00'));
    });

    test('computed fees come back in the order they were given', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('100.00'),
        cogs: Decimal.zero,
        decimals: 2,
        fees: [
          Fee(
            id: 'vat',
            name: 'VAT',
            kind: FeeKind.percent,
            value: d('10'),
            direction: FeeDirection.passThrough,
          ),
          Fee(
            id: 'promo',
            name: 'Promo',
            kind: FeeKind.percent,
            value: d('10'),
            direction: FeeDirection.discount,
          ),
        ],
      );

      expect(totals.fees.map((computed) => computed.fee.id), ['vat', 'promo']);
    });

    test('a loss reports a negative profit and a negative margin', () {
      final totals = SaleMoney.compute(
        itemsSubtotal: d('10.00'),
        cogs: d('20.00'),
        decimals: 2,
        fees: const [],
      );

      expect(totals.netProfit, d('-10.00'));
      expect(totals.netMargin < Decimal.zero, isTrue);
    });
  });
}
