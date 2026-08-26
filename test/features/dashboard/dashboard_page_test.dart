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
import 'package:mine_storage/features/dashboard/widgets/dashboard_empty_view.dart';
import 'package:mine_storage/features/dashboard/widgets/dashboard_metrics.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
final today = DateTime(2026, 8, 19);

void main() {
  late FakeProductRepository products;
  late FakeStoreRepository stores;

  setUp(() {
    products = FakeProductRepository(latency: Duration.zero);
    stores = FakeStoreRepository(
      stores: [
        storeFixture(id: 'store-a', name: 'Northside · Main', currencyId: 'cur-usd'),
      ],
      currencyList: const [usd],
    );
  });

  Future<void> pumpDashboard(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    final sales = FakeSaleRepository(products, latency: Duration.zero);
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

  group('empty store', () {
    setUp(() {
      products = FakeProductRepository(latency: Duration.zero, seedStoreId: 'store-z');
    });

    testWidgets('instructs rather than showing zeroed tiles', (tester) async {
      await pumpDashboard(tester);

      expect(find.text('No stock yet'), findsOneWidget);
      expect(find.text('Add a product'), findsOneWidget);
      expect(find.text('Scan a barcode'), findsOneWidget);
      expect(find.byType(DashboardEmptyView), findsOneWidget);
      expect(find.textContaining(r'$0.00'), findsNothing);
    });

    testWidgets('draws the art tile at the design size', (tester) async {
      await pumpDashboard(tester);

      final art = tester.widget<Container>(
        find.byKey(const Key('dashboard-empty-art')),
      );
      final constraints = art.constraints;
      expect(constraints?.maxWidth, DashboardMetrics.emptyArtSize);
      expect(constraints?.maxHeight, DashboardMetrics.emptyArtSize);
    });

    testWidgets('renders in Vietnamese without leaking a key', (tester) async {
      await pumpDashboard(tester, locale: viLocale);

      expect(find.text('Chưa có hàng'), findsOneWidget);
      expect(find.text('Thêm sản phẩm'), findsOneWidget);
      expect(find.textContaining('dashboard.'), findsNothing);
    });

    testWidgets('renders in dark without leaking a key', (tester) async {
      await pumpDashboard(tester, brightness: Brightness.dark);

      expect(find.text('No stock yet'), findsOneWidget);
      expect(find.textContaining('dashboard.'), findsNothing);
    });
  });

  group('app bar', () {
    testWidgets('names the store it is showing, from data', (tester) async {
      await pumpDashboard(tester);
      expect(find.text('Northside · Main'), findsOneWidget);
    });

    testWidgets('offers a way into settings and into the switcher', (tester) async {
      await pumpDashboard(tester);

      expect(find.byKey(const Key('dashboard-settings-button')), findsOneWidget);
      expect(find.byKey(const Key('dashboard-store-chip')), findsOneWidget);
    });

    testWidgets('shows today\'s date beside the figures', (tester) async {
      await pumpDashboard(tester);
      expect(find.textContaining('Today ·'), findsOneWidget);
    });
  });
}
