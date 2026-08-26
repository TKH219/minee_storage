import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/dashboard/widgets/store_switcher_sheet.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/providers.dart';

import '../../support/fake_store_repository.dart';
import '../../support/localization_test_harness.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
const vnd = Currency(id: 'cur-vnd', code: 'VND', symbol: '₫', decimals: 0);

Store store(String id, String name, String currencyId, StoreRole role) => Store(
  id: id,
  ownerId: 'uid-1',
  name: name,
  currencyId: currencyId,
  role: role,
);

void main() {
  Future<void> pumpSheet(
    WidgetTester tester,
    List<Store> stores, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    final prefs = await SharedPreferences.getInstance();
    final products = FakeProductRepository(latency: Duration.zero);
    final storeRepository = FakeStoreRepository(
      stores: stores,
      currencyList: const [usd, vnd],
    );

    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(products),
          storeRepositoryProvider.overrideWithValue(storeRepository),
          storeOverviewRepositoryProvider.overrideWithValue(
            FakeStoreOverviewRepository(storeRepository, products),
          ),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: const Scaffold(body: StoreSwitcherSheet()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  final mixedStores = [
    store('store-a', 'Northside · Main', 'cur-usd', StoreRole.owner),
    store('store-b', 'Northside · Depot', 'cur-usd', StoreRole.manager),
    store('store-c', 'Riverside Kiosk', 'cur-vnd', StoreRole.staff),
  ];

  testWidgets('lists every store with its currency and product count', (tester) async {
    await pumpSheet(tester, mixedStores);

    expect(find.text('Switch store'), findsOneWidget);
    expect(find.text('Northside · Main'), findsOneWidget);
    expect(find.text('Riverside Kiosk'), findsOneWidget);
    expect(find.textContaining('USD · 3 products'), findsOneWidget);
    expect(find.textContaining('VND · 0 products'), findsOneWidget);
  });

  testWidgets('badges each store with the role held there', (tester) async {
    await pumpSheet(tester, mixedStores);

    expect(find.text('Owner'), findsOneWidget);
    expect(find.text('Manager'), findsOneWidget);
    expect(find.text('Staff'), findsOneWidget);
  });

  testWidgets('offers All stores to an owner holding several', (tester) async {
    await pumpSheet(tester, mixedStores);

    expect(find.text('All stores'), findsOneWidget);
    expect(find.text('aggregate'), findsOneWidget);
  });

  testWidgets('hides All stores from a roster with no ownership', (tester) async {
    await pumpSheet(tester, [
      store('store-a', 'Main', 'cur-usd', StoreRole.manager),
      store('store-b', 'Depot', 'cur-usd', StoreRole.staff),
    ]);

    expect(find.text('All stores'), findsNothing);
  });

  testWidgets('hides All stores when there is only one store', (tester) async {
    await pumpSheet(tester, [
      store('store-a', 'Main', 'cur-usd', StoreRole.owner),
    ]);

    expect(find.text('All stores'), findsNothing);
  });

  testWidgets('says outright that currencies are never summed', (tester) async {
    await pumpSheet(tester, mixedStores);

    expect(
      find.textContaining('Totals are shown per currency, never summed'),
      findsOneWidget,
    );
    expect(find.textContaining('USD, VND'), findsOneWidget);
  });

  testWidgets('raises no currency notice on a single-currency roster', (tester) async {
    await pumpSheet(tester, [
      store('store-a', 'Main', 'cur-usd', StoreRole.owner),
      store('store-b', 'Depot', 'cur-usd', StoreRole.owner),
    ]);

    expect(find.textContaining('never summed'), findsNothing);
  });

  testWidgets('marks the store currently in view', (tester) async {
    await pumpSheet(tester, mixedStores);

    final selected = tester.widget<Container>(
      find.byKey(const Key('store-radio-store-a')),
    );
    final context = tester.element(find.byType(StoreSwitcherSheet));
    final border = (selected.decoration! as BoxDecoration).border! as Border;
    expect(border.top.color, context.colors.primary4);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpSheet(tester, mixedStores, locale: viLocale);

    expect(find.text('Đổi cửa hàng'), findsOneWidget);
    expect(find.text('Chủ cửa hàng'), findsOneWidget);
    expect(find.textContaining('stores.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpSheet(tester, mixedStores, brightness: Brightness.dark);

    expect(find.text('Switch store'), findsOneWidget);
    expect(find.textContaining('stores.'), findsNothing);
  });
}
