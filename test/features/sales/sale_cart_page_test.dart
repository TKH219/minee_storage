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
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();

    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 26)),
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

  group('basket', () {
    Future<void> fillBasket(WidgetTester tester) async {
      await tester.tap(find.byKey(const Key('sale-choose-products')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('picker-row-p1')));
      await tester.pumpAndSettle();
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('allocation-increment')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('allocation-add-to-sale')));
      await tester.pumpAndSettle();
    }

    testWidgets('a line shows its name, amount and quantity by price',
        (tester) async {
      await pumpCart(tester);
      await fillBasket(tester);

      expect(find.text('Olive oil 1L'), findsOneWidget);
      expect(find.byKey(const Key('cart-line-p1')), findsOneWidget);
      expect(find.textContaining('6.000 ×'), findsOneWidget);
    });

    testWidgets('the app bar counts the lines', (tester) async {
      await pumpCart(tester);
      await fillBasket(tester);

      expect(find.text('1 line'), findsOneWidget);
    });

    testWidgets('a split line offers the way back into its allocation',
        (tester) async {
      await pumpCart(tester);
      await fillBasket(tester);

      expect(find.text('split across 2 lots'), findsOneWidget);

      await tester.tap(find.byKey(const Key('cart-split-p1')));
      await tester.pumpAndSettle();

      expect(find.text('Quantity'), findsOneWidget);
      final quantity = tester.widget<Text>(
        find.byKey(const Key('allocation-quantity')),
      );
      expect(quantity.data, '6');
    });

    testWidgets('the money block totals what the basket holds', (tester) async {
      await pumpCart(tester);
      await fillBasket(tester);

      expect(find.byKey(const Key('cart-items-subtotal')), findsOneWidget);
      expect(find.byKey(const Key('cart-buyer-pays')), findsOneWidget);

      final subtotal = tester.widget<Text>(
        find.byKey(const Key('cart-items-subtotal')),
      );
      final buyerPays = tester.widget<Text>(
        find.byKey(const Key('cart-buyer-pays')),
      );
      expect(subtotal.data, buyerPays.data, reason: 'no fees have been added');
    });

    testWidgets('with no fees, fees and discounts reads zero', (tester) async {
      await pumpCart(tester);
      await fillBasket(tester);

      final fees = tester.widget<Text>(
        find.byKey(const Key('cart-fees-and-discounts')),
      );
      expect(fees.data, r'$0.00', reason: 'the store trades in USD');
    });

    testWidgets('Review and pay is offered once the basket has a line',
        (tester) async {
      await pumpCart(tester);
      await fillBasket(tester);

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('cart-review-and-pay')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('a single-lot line shows no split link', (tester) async {
      await pumpCart(tester);
      await tester.tap(find.byKey(const Key('sale-choose-products')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('picker-row-p1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('allocation-add-to-sale')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('cart-split-p1')), findsNothing);
    });
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
