import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/dashboard/pages/dashboard_page.dart';
import 'package:mine_storage/features/dashboard/widgets/attention_notice.dart';
import 'package:mine_storage/features/dashboard/widgets/kpi_tile.dart';
import 'package:mine_storage/features/dashboard/widgets/sparkline.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/gen/fonts.gen.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
final today = DateTime(2026, 8, 19);

void main() {
  late FakeProductRepository products;
  late FakeSaleRepository sales;
  late FakeStoreRepository stores;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    sales = FakeSaleRepository(products, latency: Duration.zero);
    stores = FakeStoreRepository(
      stores: [
        storeFixture(id: 'store-a', name: 'Northside · Main', currencyId: 'cur-usd'),
      ],
      currencyList: const [usd],
    );
  });

  SaleDraft draft({required String price, required String cost}) => SaleDraft(
    lines: [
      SaleDraftLine(
        productId: 'p3',
        productName: 'Basmati rice 5kg',
        unit: ProductUnit.kg,
        quantity: Decimal.one,
        unitSellPrice: d(price),
        allocations: [
          SaleAllocation(
            batchId: 'b4',
            batchCode: '#B-0001',
            quantity: Decimal.one,
            unitCost: d(cost),
          ),
        ],
      ),
    ],
  );

  Future<void> pumpDashboard(
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

  group('KPI tiles', () {
    testWidgets('name every figure the design draws', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('REVENUE'), findsOneWidget);
      expect(find.text('NET PROFIT'), findsOneWidget);
      expect(find.text('SALES'), findsOneWidget);
      expect(find.text('AVG BASKET'), findsOneWidget);
      expect(find.text('LAST 7 DAYS'), findsOneWidget);
      expect(find.byType(KpiTile), findsNWidgets(5));
      expect(find.byType(Sparkline), findsOneWidget);
    });

    testWidgets('show the figures the recorded sales produce', (tester) async {
      sales.recordAt(
        draft(price: '20.00', cost: '9.00'),
        storeId: 'store-a',
        at: today,
      );

      await pumpDashboard(tester);

      expect(find.text(r'$20.00'), findsWidgets);
      expect(find.text('1'), findsOneWidget);
    });

    testWidgets('render money in mono so the columns line up', (tester) async {
      sales.recordAt(
        draft(price: '20.00', cost: '9.00'),
        storeId: 'store-a',
        at: today,
      );
      await pumpDashboard(tester);

      final value = tester.widget<Text>(find.byKey(const Key('kpi-value-revenue')));
      expect(value.style?.fontFamily, FontFamily.dMMono);
      expect(
        value.style?.fontFeatures?.map((feature) => feature.feature),
        contains('tnum'),
      );
    });

    testWidgets('take the profit colour from its sign', (tester) async {
      sales.recordAt(
        draft(price: '20.00', cost: '9.00'),
        storeId: 'store-a',
        at: today,
      );
      await pumpDashboard(tester);

      final profit = tester.widget<Text>(
        find.byKey(const Key('kpi-value-netProfit')),
      );
      final context = tester.element(find.byType(DashboardPage));
      expect(profit.style?.color, context.colors.green5);
    });

    testWidgets('a loss turns the profit figure red', (tester) async {
      sales.recordAt(
        draft(price: '5.00', cost: '9.00'),
        storeId: 'store-a',
        at: today,
      );
      await pumpDashboard(tester);

      final profit = tester.widget<Text>(
        find.byKey(const Key('kpi-value-netProfit')),
      );
      final context = tester.element(find.byType(DashboardPage));
      expect(profit.style?.color, context.colors.red5);
    });

    testWidgets('a figure with nothing to compare against reads flat', (tester) async {
      await pumpDashboard(tester);
      expect(find.text('— same'), findsWidgets);
    });

    testWidgets('a rise names its percentage against yesterday', (tester) async {
      sales.recordAt(
        draft(price: '100.00', cost: '9.00'),
        storeId: 'store-a',
        at: today.subtract(const Duration(days: 1)),
      );
      sales.recordAt(
        draft(price: '118.00', cost: '9.00'),
        storeId: 'store-a',
        at: today,
      );

      await pumpDashboard(tester);

      final delta = tester.widget<Text>(find.byKey(const Key('kpi-delta-revenue')));
      expect(delta.data, '▲ 18% vs yest.');
      final context = tester.element(find.byType(DashboardPage));
      expect(delta.style?.color, context.colors.green5);
    });
  });

  group('needs attention', () {
    testWidgets('names the products behind each alert', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('NEEDS ATTENTION'), findsOneWidget);
      expect(find.byType(AttentionNotice), findsWidgets);
      expect(find.textContaining('expiring within 30 days'), findsOneWidget);
    });

    testWidgets('every alert is tappable, never a dead notice', (tester) async {
      await pumpDashboard(tester);

      final notices = tester.widgetList<AttentionNotice>(find.byType(AttentionNotice));
      expect(notices, isNotEmpty);
      for (final notice in notices) {
        expect(notice.onTap, isNotNull);
      }
    });

    testWidgets('a fall names its percentage in red', (tester) async {
      sales.recordAt(
        draft(price: '100.00', cost: '9.00'),
        storeId: 'store-a',
        at: today.subtract(const Duration(days: 1)),
      );
      sales.recordAt(
        draft(price: '96.00', cost: '9.00'),
        storeId: 'store-a',
        at: today,
      );

      await pumpDashboard(tester);

      final delta = tester.widget<Text>(find.byKey(const Key('kpi-delta-revenue')));
      expect(delta.data, '▼ 4% vs yest.');
      final context = tester.element(find.byType(DashboardPage));
      expect(delta.style?.color, context.colors.red5);
    });

    testWidgets('the wide tile carries no delta of its own', (tester) async {
      await pumpDashboard(tester);
      expect(find.byKey(const Key('kpi-delta-lastSevenDays')), findsNothing);
    });
  });

  group('localisation and dark mode', () {
    testWidgets('renders in Vietnamese without leaking a key', (tester) async {
      await pumpDashboard(tester, locale: viLocale);

      expect(find.text('DOANH THU'), findsOneWidget);
      expect(find.text('CẦN XỬ LÝ'), findsOneWidget);
      expect(find.textContaining('dashboard.'), findsNothing);
    });

    testWidgets('renders in dark without leaking a key', (tester) async {
      await pumpDashboard(tester, brightness: Brightness.dark);

      expect(find.text('REVENUE'), findsOneWidget);
      expect(find.textContaining('dashboard.'), findsNothing);
    });
  });
}
