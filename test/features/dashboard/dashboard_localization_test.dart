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
import 'package:mine_storage/features/dashboard/widgets/store_switcher_sheet.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';
import '../../support/raw_key_matcher.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
const vnd = Currency(id: 'cur-vnd', code: 'VND', symbol: '₫', decimals: 0);

void main() {
  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Locale locale,
    required Brightness brightness,
    bool stocked = true,
    List<Store>? storeList,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);

    final products = FakeProductRepository(
      latency: Duration.zero,
      seedStoreId: stocked ? 'store-a' : 'store-z',
    );
    final stores = FakeStoreRepository(
      stores: storeList ??
          [storeFixture(id: 'store-a', name: 'Northside', currencyId: 'cur-usd')],
      currencyList: const [usd, vnd],
    );

    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      ProviderScope(
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
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final mixedRoster = [
    Store(
      id: 'store-a',
      ownerId: 'uid-1',
      name: 'Northside · Main',
      currencyId: 'cur-usd',
    ),
    Store(
      id: 'store-c',
      ownerId: 'uid-1',
      name: 'Riverside Kiosk',
      currencyId: 'cur-vnd',
      role: StoreRole.staff,
    ),
  ];

  for (final locale in [enLocale, viLocale]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final tag = '${locale.languageCode} · ${brightness.name}';

      testWidgets('loaded dashboard renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          const DashboardPage(),
          locale: locale,
          brightness: brightness,
        );
        expectNoRawKeys(tester);
      });

      testWidgets('empty dashboard renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          const DashboardPage(),
          locale: locale,
          brightness: brightness,
          stocked: false,
        );
        expectNoRawKeys(tester);
      });

      testWidgets('store switcher renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          const Scaffold(body: StoreSwitcherSheet()),
          locale: locale,
          brightness: brightness,
          storeList: mixedRoster,
        );
        expectNoRawKeys(tester);
      });
    }
  }
}
