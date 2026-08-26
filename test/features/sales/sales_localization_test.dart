import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/pages/sale_cart_page.dart';
import 'package:mine_storage/features/sales/new/pages/sale_review_page.dart';
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/features/sales/pages/sales_list_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';
import '../../support/raw_key_matcher.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);

/// Every screen this spec adds, pumped in both languages and both modes, with
/// one rule: nothing may reach the user as a raw translation key.
void main() {
  late FakeProductRepository products;
  late FakeStoreRepository stores;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    stores = FakeStoreRepository(
      stores: [storeFixture(id: 'store-a', currencyId: 'cur-usd')],
      currencyList: const [usd],
    );
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Locale locale,
    required Brightness brightness,
    bool withBasket = false,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);

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
        nowProvider.overrideWithValue(() => DateTime(2026, 8, 26)),
      ],
    );
    addTearDown(container.dispose);

    if (withBasket) {
      await tester.runAsync(() async {
        final cart = container.read(saleCartStateProvider.notifier);
        await cart.load();
        final allocations = await container
            .read(saleRepositoryProvider)
            .previewAllocation(
              productId: 'p1',
              storeId: 'store-a',
              quantity: d('4'),
            );
        cart
          ..addLine(
            SaleDraftLine(
              productId: 'p1',
              productName: 'Olive oil 1L',
              unit: ProductUnit.litre,
              quantity: d('4'),
              unitSellPrice: d('20.00'),
              allocations: allocations,
            ),
          )
          ..setFees([
            Fee(
              id: 'vat',
              name: 'VAT 8%',
              kind: FeeKind.percent,
              value: d('8'),
              direction: FeeDirection.passThrough,
            ),
          ]);
      });
    }

    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final screens = <String, Widget Function()>{
    'empty cart': SaleCartPage.new,
    'sales tab': SalesListPage.new,
  };

  for (final locale in [enLocale, viLocale]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final tag = '${locale.languageCode} · ${brightness.name}';

      screens.forEach((name, build) {
        testWidgets('$name renders no raw key · $tag', (tester) async {
          await pumpScreen(
            tester,
            build(),
            locale: locale,
            brightness: brightness,
          );
          expectNoRawKeys(tester);
        });
      });

      testWidgets('basket renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          const SaleCartPage(),
          locale: locale,
          brightness: brightness,
          withBasket: true,
        );
        expectNoRawKeys(tester);
      });

      testWidgets('review renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          const SaleReviewPage(),
          locale: locale,
          brightness: brightness,
          withBasket: true,
        );
        expectNoRawKeys(tester);
      });
    }
  }
}
