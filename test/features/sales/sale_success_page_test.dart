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
import 'package:mine_storage/features/sales/new/states/sale_cart_state.dart';
import 'package:mine_storage/features/sales/new/states/sale_review_state.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);

void main() {
  late FakeProductRepository products;
  late ProviderContainer container;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
  });

  Future<void> pumpSuccess(
    WidgetTester tester, {
    StoreRole role = StoreRole.owner,
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
    PaymentMethod method = PaymentMethod.cash,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
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

    useDesignFrame(tester);
    await initLocalization();
    useLocale(locale);

    container = ProviderContainer(
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

    // Everything the screen reports has already happened by the time it is
    // shown, so the sale is confirmed for real before pumping.
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
        ..setPaymentMethod(method);

      await container.read(saleReviewStateProvider.notifier).confirm();
    });

    // The real router, so the onward actions are exercised rather than mocked.
    final router = container.read(routerProvider)
      ..go('/sales/${container.read(saleReviewStateProvider).sale!.id}/success');

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          darkTheme: AppTheme.dark(),
          scaffoldMessengerKey: snackbarKey,
        ),
      ),
    );
    // The success mark holds for MotionDurations.check (900ms). Pump past it
    // rather than settling — the Lottie keeps scheduling frames, so
    // pumpAndSettle would never return.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 1000));
  }

  testWidgets('reports what was received, how, and against which sale',
      (tester) async {
    await pumpSuccess(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('success-received'))).data,
      r'$80.00 received',
    );
    expect(find.textContaining('Cash · sale'), findsOneWidget);
    expect(find.textContaining('#1042'), findsOneWidget);
  });

  testWidgets('names the payment method actually used', (tester) async {
    await pumpSuccess(tester, method: PaymentMethod.bankTransfer);
    expect(find.textContaining('Bank transfer · sale'), findsOneWidget);
  });

  testWidgets('reports the profit and how many lots it moved', (tester) async {
    await pumpSuccess(tester);

    expect(
      tester.widget<Text>(find.byKey(const Key('success-net-profit'))).data,
      r'$31.50',
    );
    expect(
      tester.widget<Text>(find.byKey(const Key('success-stock-deducted'))).data,
      '2 lots',
    );
  });

  testWidgets('stock really has moved by the time this screen shows',
      (tester) async {
    await pumpSuccess(tester);

    final product = await tester.runAsync(
      () => products.getProduct('p1', storeId: 'store-a'),
    );
    expect(product!.totalRemaining, d('4'));
  });

  testWidgets('hides the profit row from staff', (tester) async {
    await pumpSuccess(tester, role: StoreRole.staff);

    expect(find.byKey(const Key('success-net-profit')), findsNothing);
    expect(find.text('Net profit'), findsNothing);
    expect(
      find.byKey(const Key('success-stock-deducted')),
      findsOneWidget,
      reason: 'what moved is not a secret; what it earned is',
    );
  });

  testWidgets('offers the three onward actions', (tester) async {
    await pumpSuccess(tester);

    expect(find.byKey(const Key('success-create-invoice')), findsOneWidget);
    expect(find.byKey(const Key('success-new-sale')), findsOneWidget);
    expect(find.byKey(const Key('success-back-to-dashboard')), findsOneWidget);
  });

  testWidgets('Create invoice is inert, and says so', (tester) async {
    await pumpSuccess(tester);

    await tester.tap(find.byKey(const Key('success-create-invoice')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('Coming soon'), findsOneWidget);
    expect(
      find.byKey(const Key('success-received')),
      findsOneWidget,
      reason: 'it navigates nowhere',
    );
  });

  testWidgets('starting another sale clears the basket first', (tester) async {
    await pumpSuccess(tester);

    await tester.tap(find.byKey(const Key('success-new-sale')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(container.read(saleCartStateProvider).draft.lines, isEmpty);
    expect(container.read(saleReviewStateProvider).sale, isNull);
    expect(
      find.text('Nothing in the basket'),
      findsOneWidget,
      reason: 'the next sale starts from an empty basket',
    );
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpSuccess(tester, locale: viLocale);

    expect(find.textContaining('Đã nhận'), findsOneWidget);
    expect(find.text('Tạo hóa đơn'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpSuccess(tester, brightness: Brightness.dark);

    expect(find.text('Create invoice'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
