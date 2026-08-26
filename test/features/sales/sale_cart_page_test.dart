import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/pages/sale_cart_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);

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

  Future<void> pumpCart(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      ProviderScope(
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
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: const SaleCartPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('an empty basket says so and offers both ways in', (tester) async {
    await pumpCart(tester);

    expect(find.text('New sale'), findsOneWidget);
    expect(find.text('Nothing in the basket'), findsOneWidget);
    expect(find.text('Choose from your products'), findsOneWidget);
    expect(find.text('Scan a barcode'), findsOneWidget);
  });

  testWidgets('choosing from stock leads, scanning follows', (tester) async {
    await pumpCart(tester);

    final choose = tester.getTopLeft(find.byKey(const Key('sale-choose-products')));
    final scan = tester.getTopLeft(find.byKey(const Key('sale-scan-barcode')));
    expect(choose.dy, lessThan(scan.dy));
  });

  testWidgets('an empty basket shows no money summary at all', (tester) async {
    await pumpCart(tester);

    expect(find.text('Items subtotal'), findsNothing);
    expect(find.text('Buyer pays'), findsNothing);
    expect(find.textContaining('lines'), findsNothing);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpCart(tester, locale: viLocale);

    expect(find.text('Đơn hàng mới'), findsOneWidget);
    expect(find.text('Giỏ hàng đang trống'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpCart(tester, brightness: Brightness.dark);

    expect(find.text('Nothing in the basket'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
