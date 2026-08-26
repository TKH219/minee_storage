import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_store_repository.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
const vnd = Currency(id: 'cur-vnd', code: 'VND', symbol: '₫', decimals: 0);

SaleDraftLine line({
  String productId = 'p2',
  String name = 'Whole Milk 1L',
  String quantity = '6',
  String price = '1.80',
  String cost = '1.10',
  String batchId = 'b1',
}) {
  return SaleDraftLine(
    productId: productId,
    productName: name,
    unit: ProductUnit.litre,
    quantity: d(quantity),
    unitSellPrice: d(price),
    allocations: [
      SaleAllocation(
        batchId: batchId,
        batchCode: '#B-0001',
        quantity: d(quantity),
        unitCost: d(cost),
      ),
    ],
  );
}

void main() {
  late FakeProductRepository products;
  late FakeStoreRepository stores;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    stores = FakeStoreRepository(
      stores: [
        storeFixture(id: 'store-a', name: 'Northside · Main', currencyId: 'cur-usd'),
      ],
      currencyList: const [usd, vnd],
    );
  });

  ProviderContainer containerFor() {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        saleRepositoryProvider.overrideWithValue(
          FakeSaleRepository(products, latency: Duration.zero),
        ),
        storeRepositoryProvider.overrideWithValue(stores),
        storeOverviewRepositoryProvider.overrideWithValue(
          FakeStoreOverviewRepository(stores, products),
        ),
        activeStoreProvider.overrideWith(() => FixedActiveStore('store-a')),
      ],
    );
    addTearDown(container.dispose);
    container.listen(saleCartStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  test('a fresh basket is empty and totals to zero', () async {
    final container = containerFor();
    await container.read(saleCartStateProvider.notifier).load();

    final state = container.read(saleCartStateProvider);
    expect(state.isEmpty, isTrue);
    expect(state.draft.itemsSubtotal, Decimal.zero);
    expect(state.draft.totals.buyerTotal, Decimal.zero);
  });

  test('loads the store\'s currency and the role held there', () async {
    final container = containerFor();
    await container.read(saleCartStateProvider.notifier).load();

    final state = container.read(saleCartStateProvider);
    expect(state.currency.code, 'USD');
    expect(state.role, StoreRole.owner);
    expect(state.draft.decimals, 2);
  });

  test('a VND store rounds the basket to whole units', () async {
    stores = FakeStoreRepository(
      stores: [storeFixture(id: 'store-a', currencyId: 'cur-vnd')],
      currencyList: const [usd, vnd],
    );

    final container = containerFor();
    await container.read(saleCartStateProvider.notifier).load();

    expect(container.read(saleCartStateProvider).draft.decimals, 0);
  });

  test('adding a line moves the subtotal', () async {
    final container = containerFor();
    await container.read(saleCartStateProvider.notifier).load();

    container.read(saleCartStateProvider.notifier).addLine(line());

    final state = container.read(saleCartStateProvider);
    expect(state.isEmpty, isFalse);
    expect(state.draft.lines, hasLength(1));
    expect(state.draft.itemsSubtotal, d('10.80'));
  });

  test('replacing a line keeps its place in the basket', () async {
    final container = containerFor();
    final notifier = container.read(saleCartStateProvider.notifier);
    await notifier.load();

    notifier.addLine(line(productId: 'p2', name: 'Milk'));
    notifier.addLine(line(productId: 'p3', name: 'Rice', batchId: 'b4'));
    notifier.replaceLine(0, line(productId: 'p2', name: 'Milk', quantity: '2'));

    final lines = container.read(saleCartStateProvider).draft.lines;
    expect(lines.map((each) => each.productName), ['Milk', 'Rice']);
    expect(lines.first.quantity, d('2'));
  });

  test('removing a line drops it and leaves the rest', () async {
    final container = containerFor();
    final notifier = container.read(saleCartStateProvider.notifier);
    await notifier.load();

    notifier.addLine(line(productId: 'p2', name: 'Milk'));
    notifier.addLine(line(productId: 'p3', name: 'Rice', batchId: 'b4'));
    notifier.removeLine(0);

    final lines = container.read(saleCartStateProvider).draft.lines;
    expect(lines.map((each) => each.productName), ['Rice']);
  });

  test('fees move the buyer total and leave the subtotal alone', () async {
    final container = containerFor();
    final notifier = container.read(saleCartStateProvider.notifier);
    await notifier.load();

    notifier.addLine(line(quantity: '1', price: '100.00'));
    notifier.setFees([
      Fee(
        id: 'f1',
        name: 'VAT 10%',
        kind: FeeKind.percent,
        value: d('10'),
        direction: FeeDirection.passThrough,
      ),
    ]);

    final draft = container.read(saleCartStateProvider).draft;
    expect(draft.itemsSubtotal, d('100.00'));
    expect(draft.totals.buyerTotal, d('110.00'));
  });

  test('the payment method is recorded on the draft', () async {
    final container = containerFor();
    final notifier = container.read(saleCartStateProvider.notifier);
    await notifier.load();

    notifier.setPaymentMethod(PaymentMethod.card);

    expect(
      container.read(saleCartStateProvider).draft.paymentMethod,
      PaymentMethod.card,
    );
  });

  test('reset empties the basket so the next sale starts clean', () async {
    final container = containerFor();
    final notifier = container.read(saleCartStateProvider.notifier);
    await notifier.load();

    notifier.addLine(line());
    notifier.setFees([
      Fee(
        id: 'f1',
        name: 'Promo',
        kind: FeeKind.fixed,
        value: d('1.00'),
        direction: FeeDirection.discount,
      ),
    ]);
    notifier.reset();

    final state = container.read(saleCartStateProvider);
    expect(state.isEmpty, isTrue);
    expect(state.draft.fees, isEmpty);
    expect(state.currency.code, 'USD', reason: 'the store survives a reset');
  });

  test('a draft holds no stock — nothing is deducted by building one', () async {
    final container = containerFor();
    final notifier = container.read(saleCartStateProvider.notifier);
    await notifier.load();

    notifier.addLine(line(productId: 'p1', batchId: 'b1', quantity: '2'));

    final product = await products.getProduct('p1', storeId: 'store-a');
    expect(product.totalRemaining, d('8'));
  });
}
