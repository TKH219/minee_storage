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

/// The design's worked example: 35.80 of goods costing 25.00, a 5% promo, 8%
/// VAT, a 2.00 delivery the store keeps, and a 1.5% card fee it pays.
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
  late FakeProductRepository products;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
  });

  Future<void> pumpReview(
    WidgetTester tester, {
    StoreRole role = StoreRole.owner,
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
    List<Fee> fees = const [],
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

    final cart = container.read(saleCartStateProvider.notifier);
    // Repository reads schedule timers, and inside testWidgets a timer only
    // fires when the tester pumps — so the basket is built outside the fake
    // clock, before the widget under test exists.
    await tester.runAsync(cart.load);
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
      ..setFees(fees);

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

  group('owner view', () {
    testWidgets('shows both truths, with the design\'s worked figures',
        (tester) async {
      await pumpReview(tester, fees: workedExampleFees);

      String value(String key) =>
          tester.widget<Text>(find.byKey(Key(key))).data!;

      expect(value('review-items-subtotal'), r'$35.80');
      expect(value('review-fee-promo'), r'−$1.79');
      expect(value('review-fee-vat'), r'+$2.72');
      expect(value('review-fee-delivery'), r'+$2.00');
      expect(value('review-buyer-pays'), r'$38.73');
      expect(value('review-less-pass-through'), r'−$3.23');
      expect(value('review-net-revenue'), r'$35.50');
      expect(value('review-cost-of-goods'), r'−$25.00');
      expect(value('review-net-profit'), r'$10.50');
    });

    testWidgets('names the margin on the profit row', (tester) async {
      await pumpReview(tester, fees: workedExampleFees);
      expect(find.textContaining('29.6% margin'), findsOneWidget);
    });

    testWidgets('marks a pass-through fee as one the store keeps none of',
        (tester) async {
      await pumpReview(tester, fees: workedExampleFees);
      expect(find.text('remitted, you keep none'), findsOneWidget);
    });

    testWidgets('shows no role lock', (tester) async {
      await pumpReview(tester, fees: workedExampleFees);
      expect(find.textContaining('hidden for your role'), findsNothing);
    });
  });

  group('staff view', () {
    testWidgets('omits cost and profit entirely — they are absent, not masked',
        (tester) async {
      await pumpReview(
        tester,
        role: StoreRole.staff,
        fees: workedExampleFees,
      );

      expect(find.byKey(const Key('review-net-revenue')), findsNothing);
      expect(find.byKey(const Key('review-cost-of-goods')), findsNothing);
      expect(find.byKey(const Key('review-net-profit')), findsNothing);
      expect(find.byKey(const Key('review-less-pass-through')), findsNothing);
      expect(find.text('Net revenue'), findsNothing);
      expect(find.text('Cost of goods'), findsNothing);
    });

    testWidgets('leaves the buyer total exactly as the owner sees it',
        (tester) async {
      await pumpReview(tester, role: StoreRole.staff, fees: workedExampleFees);

      expect(
        tester.widget<Text>(find.byKey(const Key('review-buyer-pays'))).data,
        r'$38.73',
      );
    });

    testWidgets('says why the rows are missing', (tester) async {
      await pumpReview(tester, role: StoreRole.staff, fees: workedExampleFees);
      expect(
        find.text('Cost and profit are hidden for your role.'),
        findsOneWidget,
      );
    });
  });

  group('payment method', () {
    testWidgets('offers all four and marks the chosen one', (tester) async {
      await pumpReview(tester);

      expect(find.text('Cash'), findsOneWidget);
      expect(find.text('Bank transfer'), findsOneWidget);
      expect(find.text('Card'), findsOneWidget);
      expect(find.text('E-wallet'), findsOneWidget);

      final context = tester.element(find.byType(SaleReviewPage));
      final cash = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('payment-cash')),
          matching: find.byType(Container),
        ),
      );
      final border = (cash.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, context.colors.inkPrimary);
    });

    testWidgets('choosing another method moves the selection', (tester) async {
      await pumpReview(tester);

      await tester.tap(find.byKey(const Key('payment-card')));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(SaleReviewPage));
      final card = tester.widget<Container>(
        find.descendant(
          of: find.byKey(const Key('payment-card')),
          matching: find.byType(Container),
        ),
      );
      final border = (card.decoration! as BoxDecoration).border! as Border;
      expect(border.top.color, context.colors.inkPrimary);
    });
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpReview(tester, locale: viLocale, fees: workedExampleFees);

    expect(find.text('Xem lại & thanh toán'), findsOneWidget);
    expect(find.text('Khách trả'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpReview(tester, brightness: Brightness.dark, fees: workedExampleFees);

    expect(find.text('Review & pay'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
