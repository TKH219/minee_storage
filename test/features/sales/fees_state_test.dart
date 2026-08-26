import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/new/states/fees_state.dart';

Decimal d(String value) => Decimal.parse(value);

Fee fee({
  String id = 'f1',
  String name = 'Fee',
  FeeKind kind = FeeKind.fixed,
  String value = '1.00',
  FeeDirection direction = FeeDirection.buyerCharge,
}) {
  return Fee(
    id: id,
    name: name,
    kind: kind,
    value: d(value),
    direction: direction,
  );
}

void main() {
  ProviderContainer containerWith({
    String subtotal = '35.80',
    List<Fee> fees = const [],
  }) {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    container.listen(feesStateProvider, (_, _) {}, fireImmediately: true);
    container
        .read(feesStateProvider.notifier)
        .open(itemsSubtotal: d(subtotal), fees: fees, decimals: 2);
    return container;
  }

  group('the base each fee is charged on', () {
    test('a percent discount is charged on the items subtotal', () {
      final container = containerWith();
      container.read(feesStateProvider.notifier).addFee(
        fee(
          id: 'promo',
          name: 'Promo 5%',
          kind: FeeKind.percent,
          value: '5',
          direction: FeeDirection.discount,
        ),
      );

      final computed = container.read(feesStateProvider).computed.single;
      expect(computed.amount, d('1.79'));
      expect(computed.base, d('35.80'));
    });

    test('a percent fee after a discount is charged on the discounted amount', () {
      final container = containerWith();
      final notifier = container.read(feesStateProvider.notifier)
        ..addFee(
          fee(
            id: 'promo',
            name: 'Promo 5%',
            kind: FeeKind.percent,
            value: '5',
            direction: FeeDirection.discount,
          ),
        )
        ..addFee(
          fee(
            id: 'vat',
            name: 'VAT 8%',
            kind: FeeKind.percent,
            value: '8',
            direction: FeeDirection.passThrough,
          ),
        );
      expect(notifier, isNotNull);

      final vat = container
          .read(feesStateProvider)
          .computed
          .firstWhere((each) => each.fee.id == 'vat');
      expect(vat.base, d('34.01'));
      expect(vat.amount, d('2.72'));
    });

    test('the same fee with no discount present is charged on the full subtotal', () {
      final container = containerWith();
      container.read(feesStateProvider.notifier).addFee(
        fee(
          id: 'vat',
          name: 'VAT 8%',
          kind: FeeKind.percent,
          value: '8',
          direction: FeeDirection.passThrough,
        ),
      );

      final vat = container.read(feesStateProvider).computed.single;
      expect(vat.base, d('35.80'));
    });

    test('a fixed fee names no base', () {
      final container = containerWith();
      container.read(feesStateProvider.notifier).addFee(fee(value: '2.00'));

      expect(container.read(feesStateProvider).computed.single.base, isNull);
    });
  });

  group('each direction moves the totals its own way', () {
    test('a discount lowers what the buyer pays and what the store keeps', () {
      final container = containerWith(subtotal: '100.00');
      container.read(feesStateProvider.notifier).addFee(
        fee(value: '10.00', direction: FeeDirection.discount),
      );

      final totals = container.read(feesStateProvider).totals;
      expect(totals.buyerTotal, d('90.00'));
      expect(totals.netRevenue, d('90.00'));
    });

    test('a pass-through raises the buyer total and not net revenue', () {
      final container = containerWith(subtotal: '100.00');
      container.read(feesStateProvider.notifier).addFee(
        fee(value: '10.00', direction: FeeDirection.passThrough),
      );

      final totals = container.read(feesStateProvider).totals;
      expect(totals.buyerTotal, d('110.00'));
      expect(totals.netRevenue, d('100.00'));
    });

    test('a buyer charge the store keeps raises both', () {
      final container = containerWith(subtotal: '100.00');
      container.read(feesStateProvider.notifier).addFee(
        fee(value: '10.00', direction: FeeDirection.buyerCharge),
      );

      final totals = container.read(feesStateProvider).totals;
      expect(totals.buyerTotal, d('110.00'));
      expect(totals.netRevenue, d('110.00'));
    });

    test('your own cost leaves the buyer untouched and lowers net revenue', () {
      final container = containerWith(subtotal: '100.00');
      container.read(feesStateProvider.notifier).addFee(
        fee(value: '10.00', direction: FeeDirection.sellerCost),
      );

      final totals = container.read(feesStateProvider).totals;
      expect(totals.buyerTotal, d('100.00'));
      expect(totals.netRevenue, d('90.00'));
    });
  });

  group('editing the list', () {
    test('removing a fee restores the previous totals exactly', () {
      final container = containerWith(subtotal: '100.00');
      final notifier = container.read(feesStateProvider.notifier);
      final before = container.read(feesStateProvider).totals.buyerTotal;

      notifier.addFee(fee(id: 'x', value: '10.00'));
      expect(container.read(feesStateProvider).totals.buyerTotal, isNot(before));

      notifier.removeFee('x');
      expect(container.read(feesStateProvider).totals.buyerTotal, before);
    });

    test('the order fees were added in does not change any amount', () {
      final discount = fee(
        id: 'promo',
        kind: FeeKind.percent,
        value: '10',
        direction: FeeDirection.discount,
      );
      final vat = fee(
        id: 'vat',
        kind: FeeKind.percent,
        value: '10',
        direction: FeeDirection.passThrough,
      );

      final discountFirst = containerWith(subtotal: '100.00', fees: [discount, vat]);
      final vatFirst = containerWith(subtotal: '100.00', fees: [vat, discount]);

      expect(
        discountFirst.read(feesStateProvider).totals.buyerTotal,
        vatFirst.read(feesStateProvider).totals.buyerTotal,
      );
      expect(discountFirst.read(feesStateProvider).totals.buyerTotal, d('99.00'));
    });

    test('opening with existing fees shows them', () {
      final container = containerWith(fees: [fee(id: 'a'), fee(id: 'b')]);
      expect(container.read(feesStateProvider).fees, hasLength(2));
    });

    test('each added fee gets an id of its own', () {
      final container = containerWith();
      final notifier = container.read(feesStateProvider.notifier)
        ..addFee(fee(id: '', name: 'One'))
        ..addFee(fee(id: '', name: 'Two'));
      expect(notifier, isNotNull);

      final ids = container.read(feesStateProvider).fees.map((each) => each.id);
      expect(ids.toSet(), hasLength(2));
    });
  });

  test('the worked example on S22 and S23 falls out of the editor', () {
    final container = containerWith(
      fees: [
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
      ],
    );

    final state = container.read(feesStateProvider);
    expect(state.amountFor('promo'), d('-1.79'));
    expect(state.amountFor('vat'), d('2.72'));
    expect(state.amountFor('delivery'), d('2.00'));
    expect(state.amountFor('card'), d('-0.51'));
    expect(state.totals.buyerTotal, d('38.73'));
  });
}
