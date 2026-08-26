import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  Fee fee(String id, String name, FeeDirection direction, FeeKind kind, String value) =>
      Fee(id: id, name: name, kind: kind, value: Decimal.parse(value), direction: direction);

  final workedExample = [
    fee('p', 'Promo', FeeDirection.discount, FeeKind.percent, '5'),
    fee('v', 'VAT', FeeDirection.passThrough, FeeKind.percent, '8'),
    fee('d', 'Delivery', FeeDirection.buyerCharge, FeeKind.fixed, '2.00'),
    fee('c', 'Card', FeeDirection.sellerCost, FeeKind.percent, '1.5'),
  ];

  group('the money a transaction freezes', () {
    test('the design\'s worked example lands to the cent', () {
      final money = TransactionMoney.compute(
        type: TransactionType.sale,
        itemsSubtotal: Decimal.parse('35.80'),
        cogs: Decimal.parse('25.00'),
        fees: workedExample,
        decimals: 2,
      );

      expect(money.itemsSubtotal, Decimal.parse('35.80'));
      expect(money.discountTotal, Decimal.parse('1.79'));
      expect(money.buyerChargeTotal, Decimal.parse('4.72'));
      expect(money.passThroughTotal, Decimal.parse('2.72'));
      expect(money.sellerCostTotal, Decimal.parse('0.51'));
      expect(money.buyerTotal, Decimal.parse('38.73'));
      expect(money.netRevenue, Decimal.parse('35.50'));
      expect(money.cogs, Decimal.parse('25.00'));
      expect(money.grossProfit, Decimal.parse('9.01'));
      expect(money.netProfit, Decimal.parse('10.50'));
    });

    test('a percent fee added after a discount charges on the discounted base', () {
      final money = TransactionMoney.compute(
        type: TransactionType.sale,
        itemsSubtotal: Decimal.parse('35.80'),
        cogs: Decimal.zero,
        fees: workedExample,
        decimals: 2,
      );

      final vat = money.fees.firstWhere((computed) => computed.fee.name == 'VAT');
      expect(vat.base, Decimal.parse('34.01'));
      expect(vat.amount, Decimal.parse('2.72'));
    });

    test('a VND basket rounds to whole dong with no fractional remainder', () {
      final money = TransactionMoney.compute(
        type: TransactionType.sale,
        itemsSubtotal: Decimal.parse('358000'),
        cogs: Decimal.parse('250000'),
        fees: [fee('v', 'VAT', FeeDirection.passThrough, FeeKind.percent, '8')],
        decimals: 0,
      );

      expect(money.buyerTotal, Decimal.parse('386640'));
      expect(money.buyerTotal.scale, 0);
      expect(money.passThroughTotal.scale, 0);
    });

    test('a receive carries no revenue and no profit', () {
      final money = TransactionMoney.compute(
        type: TransactionType.receive,
        itemsSubtotal: Decimal.parse('400.00'),
        cogs: Decimal.zero,
        fees: [fee('s', 'Shipping', FeeDirection.buyerCharge, FeeKind.fixed, '40.00')],
        decimals: 2,
      );

      expect(money.buyerTotal, Decimal.parse('440.00'), reason: 'what was paid to the supplier');
      expect(money.netRevenue, Decimal.zero);
      expect(money.grossProfit, Decimal.zero);
      expect(money.netProfit, Decimal.zero);
      expect(money.netMargin, Decimal.zero);
    });

    test('a write-off carries only the cost of what left', () {
      final money = TransactionMoney.compute(
        type: TransactionType.writeOff,
        itemsSubtotal: Decimal.zero,
        cogs: Decimal.parse('42.00'),
        fees: const [],
        decimals: 2,
      );

      expect(money.cogs, Decimal.parse('42.00'));
      expect(money.buyerTotal, Decimal.zero);
      expect(money.netRevenue, Decimal.zero);
      expect(money.netProfit, Decimal.zero);
    });

    test('an adjust moves no money figure at all', () {
      final money = TransactionMoney.compute(
        type: TransactionType.adjust,
        itemsSubtotal: Decimal.zero,
        cogs: Decimal.parse('8.00'),
        fees: const [],
        decimals: 2,
      );

      expect(money.cogs, Decimal.parse('8.00'));
      expect(money.itemsSubtotal, Decimal.zero);
      expect(money.buyerTotal, Decimal.zero);
      expect(money.netRevenue, Decimal.zero);
    });

    test('a margin below minus one hundred percent is representable', () {
      final money = TransactionMoney.compute(
        type: TransactionType.sale,
        itemsSubtotal: Decimal.parse('10.00'),
        cogs: Decimal.parse('50.00'),
        fees: const [],
        decimals: 2,
      );

      expect(money.netProfit, Decimal.parse('-40.00'));
      expect(money.netMargin < Decimal.fromInt(-1), isTrue);
    });
  });
}
