import '../../support/fake_store_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/app/router/app_router.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/app_nav_bar.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/fake_auth_repository.dart';

import '../../support/localization_test_harness.dart';

Widget shellApp({
  required String initialLocation,
  required SharedPreferences prefs,
  ProductRepository? products,
}) {
  final container = ProviderContainer(
    overrides: [
      authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
      storeRepositoryProvider.overrideWithValue(
        FakeStoreRepository(stores: [storeFixture()]),
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
      if (products != null) productRepositoryProvider.overrideWithValue(products),
    ],
  );
  final router = container.read(routerProvider);
  router.go(initialLocation);

  return UncontrolledProviderScope(
    container: container,
    child: MaterialApp.router(
      routerConfig: router,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      scaffoldMessengerKey: snackbarKey,
    ),
  );
}

void main() {
  setUp(useLocale);

  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('the reports tab renders its placeholder under the bar', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/reports', prefs: prefs));
    await tester.pumpAndSettle();

    expect(find.byType(AppNavBar), findsOneWidget);
    expect(find.text('Nothing to report yet'), findsOneWidget);
  });

  testWidgets('every tab keeps the bar present', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/reports', prefs: prefs));
    await tester.pumpAndSettle();

    for (final tab in ['Dashboard', 'Products', 'Sales']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
      expect(find.byType(AppNavBar), findsOneWidget, reason: tab);
    }
  });

  testWidgets('splash and sign-in show no navigation bar', (tester) async {
    await tester.pumpWidget(shellApp(initialLocation: '/sign-in', prefs: prefs));
    await tester.pumpAndSettle();
    expect(find.byType(AppNavBar), findsNothing);
  });

  testWidgets('the centre action starts a sale, covering the nav bar', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    final withStore = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      shellApp(
        initialLocation: '/reports',
        prefs: withStore,
        products: FakeProductRepository(latency: Duration.zero),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('new-sale-circle')));
    await tester.pumpAndSettle();

    expect(find.text('Nothing in the basket'), findsOneWidget);
    expect(find.byType(AppNavBar), findsNothing);
  });

  testWidgets('the products list can still add a product, now the FAB sells', (tester) async {
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    final withStore = await SharedPreferences.getInstance();
    final repository = _GrowingRepository();

    await tester.pumpWidget(
      shellApp(initialLocation: '/products', prefs: withStore, products: repository),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your shelves are empty'), findsOneWidget);

    // Something else creates a product while the sheet is open — exactly what
    // the real form does over the network.
    repository.hasProduct = true;

    await tester.tap(find.byKey(const Key('products-add-button')));
    await tester.pumpAndSettle();
    expect(find.byKey(const Key('add-scan-tile')), findsOneWidget);
    await tester.tap(find.byKey(const Key('add-manual-tile')));
    await tester.pumpAndSettle();

    // Back out of the form the way the user does.
    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('Your shelves are empty'), findsNothing);
    expect(find.text('Bench Oil'), findsOneWidget);
  });
}

/// Empty until something creates a product, which is the state the list is left
/// in while the add sheet and the form are on top of it.
class _GrowingRepository extends FakeProductRepository {
  _GrowingRepository() : super(latency: Duration.zero);

  bool hasProduct = false;

  @override
  Future<PagedProducts> getProducts({
    required String storeId,
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async {
    if (!hasProduct) return const PagedProducts(items: [], hasMore: false);
    return PagedProducts(
      items: [
        ProductEntity(
          id: 'new',
          name: 'Bench Oil',
          unit: ProductUnit.litre,
          createdAt: DateTime(2026, 8, 25),
          updatedAt: DateTime(2026, 8, 25),
        ),
      ],
      hasMore: false,
    );
  }
}
