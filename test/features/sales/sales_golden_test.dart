import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/pages/sale_review_page.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);

/// The design's worked example, so the golden carries the same figures the
/// spec checks the arithmetic against.
final workedExampleFees = [
  Fee(
    id: 'promo',
    name: 'Promo 5%',
    kind: FeeKind.percent,
    value: d('5'),
    direction: FeeDirection.discount,
  ),
  Fee(
    id: 'vat',
    name: 'VAT 8%',
    kind: FeeKind.percent,
    value: d('8'),
    direction: FeeDirection.passThrough,
  ),
  Fee(
    id: 'delivery',
    name: 'Delivery',
    kind: FeeKind.fixed,
    value: d('2.00'),
    direction: FeeDirection.buyerCharge,
  ),
  Fee(
    id: 'card',
    name: 'Card fee 1.5%',
    kind: FeeKind.percent,
    value: d('1.5'),
    direction: FeeDirection.sellerCost,
  ),
];

void main() {
  Future<void> pumpReview(
    WidgetTester tester, {
    required Brightness brightness,
    required StoreRole role,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);

    final products = FakeProductRepository(latency: Duration.zero);
    final stores = FakeStoreRepository(
      stores: [
        Store(
          id: 'store-a',
          ownerId: 'uid-1',
          name: 'Northside',
          currencyId: 'cur-usd',
          role: role,
        ),
      ],
      currencyList: const [usd],
    );

    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
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

    await tester.runAsync(() async {
      final cart = container.read(saleCartStateProvider.notifier);
      await cart.load();
      cart
        ..addLine(
          SaleDraftLine(
            productId: 'p1',
            productName: 'Olive oil 1L',
            unit: ProductUnit.litre,
            quantity: d('2'),
            unitSellPrice: d('17.90'),
            allocations: [
              SaleAllocation(
                batchId: 'b1',
                batchCode: '#B-0001',
                quantity: d('2'),
                unitCost: d('12.50'),
              ),
            ],
          ),
        )
        ..setFees(workedExampleFees);
    });

    await initLocalization();
    useLocale();
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: const SaleReviewPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (brightness, tag) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets('sale review owner golden · $tag', (tester) async {
      await pumpReview(tester, brightness: brightness, role: StoreRole.owner);
      await expectLater(
        find.byType(SaleReviewPage),
        matchesGoldenFile('../../goldens/sale_review_owner_$tag.png'),
      );
    });

    testWidgets('sale review staff golden · $tag', (tester) async {
      await pumpReview(tester, brightness: brightness, role: StoreRole.staff);
      await expectLater(
        find.byType(SaleReviewPage),
        matchesGoldenFile('../../goldens/sale_review_staff_$tag.png'),
      );
    });
  }
}
