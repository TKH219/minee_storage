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
import 'package:mine_storage/features/dashboard/pages/dashboard_page.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
final today = DateTime(2026, 8, 19);

void main() {
  Future<void> pumpDashboard(
    WidgetTester tester, {
    required Brightness brightness,
    required bool stocked,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);

    final products = FakeProductRepository(
      latency: Duration.zero,
      seedStoreId: stocked ? 'store-a' : 'store-z',
    );
    final sales = FakeSaleRepository(products, latency: Duration.zero);
    final stores = FakeStoreRepository(
      stores: [
        storeFixture(id: 'store-a', name: 'Northside · Main', currencyId: 'cur-usd'),
      ],
      currencyList: const [usd],
    );

    if (stocked) {
      // A day's trading, so the tiles carry figures rather than zeroes.
      sales.recordAt(
        SaleDraft(
          lines: [
            SaleDraftLine(
              productId: 'p3',
              productName: 'Basmati rice 5kg',
              unit: ProductUnit.kg,
              quantity: d('2'),
              unitSellPrice: d('20.00'),
              allocations: [
                SaleAllocation(
                  batchId: 'b4',
                  batchCode: '#B-0001',
                  quantity: d('2'),
                  unitCost: d('9.00'),
                ),
              ],
            ),
          ],
        ),
        storeId: 'store-a',
        at: today,
      );
    }

    await initLocalization();
    useLocale();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(products),
          saleRepositoryProvider.overrideWithValue(sales),
          storeRepositoryProvider.overrideWithValue(stores),
          storeOverviewRepositoryProvider.overrideWithValue(
            FakeStoreOverviewRepository(stores, products),
          ),
          activeStoreProvider.overrideWith(() => FixedActiveStore('store-a')),
          nowProvider.overrideWithValue(() => today),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: const DashboardPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final (brightness, tag) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets('dashboard loaded golden · $tag', (tester) async {
      await pumpDashboard(tester, brightness: brightness, stocked: true);
      await expectLater(
        find.byType(DashboardPage),
        matchesGoldenFile('../../goldens/dashboard_loaded_$tag.png'),
      );
    });

    testWidgets('dashboard empty golden · $tag', (tester) async {
      await pumpDashboard(tester, brightness: brightness, stocked: false);
      await expectLater(
        find.byType(DashboardPage),
        matchesGoldenFile('../../goldens/dashboard_empty_$tag.png'),
      );
    });
  }
}
