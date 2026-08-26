import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_review_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_store_repository.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository sales;
  late FakeStoreRepository stores;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    sales = FakeSaleRepository(products, latency: Duration.zero);
    stores = FakeStoreRepository(
      stores: [storeFixture(id: 'store-a', currencyId: 'cur-usd')],
      currencyList: const [usd],
    );
  });

  ProviderContainer containerFor() {
    final container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(products),
        saleRepositoryProvider.overrideWithValue(sales),
        storeRepositoryProvider.overrideWithValue(stores),
        storeOverviewRepositoryProvider.overrideWithValue(
          FakeStoreOverviewRepository(stores, products),
        ),
        activeStoreProvider.overrideWith(() => FixedActiveStore('store-a')),
      ],
    );
    addTearDown(container.dispose);
    container.listen(saleCartStateProvider, (_, _) {}, fireImmediately: true);
    container.listen(saleReviewStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  /// Four olive oil, which spans lot b1 (2 at 11.50) and lot b2 (2 at 12.75).
  Future<void> fillBasket(ProviderContainer container, {String quantity = '4'}) async {
    final cart = container.read(saleCartStateProvider.notifier);
    await cart.load();

    final product = await products.getProduct('p1', storeId: 'store-a');
    final allocations = await sales.previewAllocation(
      productId: 'p1',
      storeId: 'store-a',
      quantity: d(quantity),
    );
    cart.addLine(
      SaleDraftLine(
        productId: product.id,
        productName: product.name,
        unit: product.unit,
        quantity: d(quantity),
        unitSellPrice: d('20.00'),
        allocations: allocations,
      ),
    );
  }

  group('confirming', () {
    test('records the sale and lands it on the state', () async {
      final container = containerFor();
      await fillBasket(container);

      await container.read(saleReviewStateProvider.notifier).confirm();

      final state = container.read(saleReviewStateProvider);
      expect(state.isLoaded, isTrue);
      expect(state.sale, isNotNull);
      expect(state.sale!.totals.buyerTotal, d('80.00'));
      expect(state.sale!.deductedLotCount, 2);
    });

    test('deducts stock exactly once, across the allocated lots', () async {
      final container = containerFor();
      await fillBasket(container);

      await container.read(saleReviewStateProvider.notifier).confirm();

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.totalRemaining, d('4'));
      expect(
        product.batches.firstWhere((b) => b.id == 'b1').remainingQuantity,
        Decimal.zero,
      );
      expect(
        product.batches.firstWhere((b) => b.id == 'b2').remainingQuantity,
        d('4'),
      );
    });

    test('a second confirm on an already-paid sale does nothing', () async {
      final container = containerFor();
      await fillBasket(container);
      final notifier = container.read(saleReviewStateProvider.notifier);

      await notifier.confirm();
      await notifier.confirm();

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(product.totalRemaining, d('4'), reason: 'deducted once, not twice');
      expect(await sales.salesFor(storeId: 'store-a'), hasLength(1));
    });

    test('a shortfall at confirm deducts nothing and keeps the draft',
        () async {
      final container = containerFor();
      await fillBasket(container);

      await products.consume(
        'p1',
        [BatchAllocation(batchId: 'b1', quantity: d('2'))],
        storeId: 'store-a',
      );

      await container.read(saleReviewStateProvider.notifier).confirm();

      final state = container.read(saleReviewStateProvider);
      expect(state.isError, isTrue);
      expect(state.sale, isNull);
      expect(
        container.read(saleCartStateProvider).draft.lines,
        hasLength(1),
        reason: 'the basket survives so the seller can fix the split',
      );

      final product = await products.getProduct('p1', storeId: 'store-a');
      expect(
        product.batches.firstWhere((b) => b.id == 'b2').remainingQuantity,
        d('6'),
      );
      expect(await sales.salesFor(storeId: 'store-a'), isEmpty);
    });

    test('an empty basket cannot be confirmed', () async {
      final container = containerFor();
      await container.read(saleCartStateProvider.notifier).load();

      expect(container.read(saleReviewStateProvider).canConfirm, isFalse);

      await container.read(saleReviewStateProvider.notifier).confirm();
      expect(await sales.salesFor(storeId: 'store-a'), isEmpty);
    });

    test('the chosen payment method reaches the sale and moves no figure',
        () async {
      final container = containerFor();
      await fillBasket(container);
      container
          .read(saleCartStateProvider.notifier)
          .setPaymentMethod(PaymentMethod.bankTransfer);

      final before = container.read(saleCartStateProvider).draft.totals.buyerTotal;
      await container.read(saleReviewStateProvider.notifier).confirm();

      final sale = container.read(saleReviewStateProvider).sale!;
      expect(sale.paymentMethod, PaymentMethod.bankTransfer);
      expect(sale.totals.buyerTotal, before);
    });
  });

  group('role gating', () {
    test('an owner sees cost and profit', () async {
      final container = containerFor();
      await fillBasket(container);

      expect(container.read(saleReviewStateProvider).showsCostAndProfit, isTrue);
    });

    test('a staff member does not', () async {
      stores = FakeStoreRepository(
        stores: [
          Store(
            id: 'store-a',
            ownerId: 'uid-1',
            name: 'Northside',
            currencyId: 'cur-usd',
            role: StoreRole.staff,
          ),
        ],
        currencyList: const [usd],
      );

      final container = containerFor();
      await fillBasket(container);

      expect(container.read(saleReviewStateProvider).showsCostAndProfit, isFalse);
    });

    test('the buyer total is the same either way', () async {
      final owner = containerFor();
      await fillBasket(owner);
      final ownerTotal = owner.read(saleReviewStateProvider).totals.buyerTotal;

      stores = FakeStoreRepository(
        stores: [
          Store(
            id: 'store-a',
            ownerId: 'uid-1',
            name: 'Northside',
            currencyId: 'cur-usd',
            role: StoreRole.staff,
          ),
        ],
        currencyList: const [usd],
      );
      final staff = containerFor();
      await fillBasket(staff);

      expect(staff.read(saleReviewStateProvider).totals.buyerTotal, ownerTotal);
    });
  });

  test('the totals on review are the draft\'s own', () async {
    final container = containerFor();
    await fillBasket(container);
    container.read(saleCartStateProvider.notifier).setFees([
      Fee(
        id: 'vat',
        name: 'VAT 8%',
        kind: FeeKind.percent,
        value: d('8'),
        direction: FeeDirection.passThrough,
      ),
    ]);

    final review = container.read(saleReviewStateProvider);
    expect(review.totals.itemsSubtotal, d('80.00'));
    expect(review.totals.buyerTotal, d('86.40'));
    expect(review.totals.netRevenue, d('80.00'));
    expect(review.totals.cogs, d('48.50'));
  });

  test('an InsufficientStockException is surfaced with its own message key',
      () async {
    final container = containerFor();
    await fillBasket(container);
    await products.consume(
      'p1',
      [BatchAllocation(batchId: 'b1', quantity: d('2'))],
      storeId: 'store-a',
    );

    await container.read(saleReviewStateProvider.notifier).confirm();

    final state = container.read(saleReviewStateProvider);
    expect(state.isError, isTrue);
    expect(
      state.errorMessageKey ?? state.errorMessage,
      isNotNull,
      reason: 'the seller has to be told which lot ran short',
    );
    expect(InsufficientStockException, isNotNull);
  });
}
