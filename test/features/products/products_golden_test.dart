import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/features/products/detail/pages/product_detail_page.dart';
import 'package:mine_storage/features/products/form/pages/product_form_page.dart';
import 'package:mine_storage/features/products/pages/product_list_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

/// The clock is pinned: an expiry badge means something different tomorrow, so
/// an unpinned golden would drift from "expiring soon" to "expired" on its own.
final _today = DateTime(2026, 8, 20);

ProductBatchEntity _batch({
  required String id,
  required String code,
  DateTime? expiry,
  String price = '1.10',
  String remaining = '2',
}) {
  return ProductBatchEntity(
    id: id,
    productId: 'p1',
    storeId: 'store-a',
    batchCode: code,
    purchasedAt: DateTime(2026, 8, 8),
    unitPrice: Decimal.parse(price),
    expiryDate: expiry,
    initialQuantity: Decimal.parse('12'),
    remainingQuantity: Decimal.parse(remaining),
    createdAt: DateTime(2026, 8, 8),
    updatedAt: DateTime(2026, 8, 8),
    storageLocation: 'Cold room A',
  );
}

final _milk = ProductEntity(
  id: 'p1',
  name: 'Whole Milk 1L',
  unit: ProductUnit.litre,
  brand: 'Dairyland',
  category: 'Dairy',
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 8),
  batches: [
    _batch(id: 'b1', code: '#B-0001', expiry: DateTime(2026, 8, 22), remaining: '2'),
    _batch(id: 'b2', code: '#B-0002', expiry: DateTime(2026, 9, 12), price: '1.25', remaining: '8'),
  ],
);

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    prefs = await SharedPreferences.getInstance();
  });

  void sizeToPhone(WidgetTester tester) {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget host(Widget child, ThemeData theme, FakeProductRepository repository) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        productRepositoryProvider.overrideWithValue(repository),
        nowProvider.overrideWithValue(() => _today),
      ],
      child: Theme(data: theme, child: child),
    );
  }

  for (final (theme, tag) in [(AppTheme.light(), 'light'), (AppTheme.dark(), 'dark')]) {
    testWidgets('product list golden · $tag', (tester) async {
      sizeToPhone(tester);
      await pumpLocalizedApp(
        tester,
        host(const ProductListPage(), theme, _ListRepository()),
      );
      await expectLater(
        find.byType(ProductListPage),
        matchesGoldenFile('../../goldens/products_list_$tag.png'),
      );
    });

    testWidgets('product detail golden · $tag', (tester) async {
      sizeToPhone(tester);
      await pumpLocalizedApp(
        tester,
        host(const ProductDetailPage(productId: 'p1'), theme, _DetailRepository()),
      );
      await expectLater(
        find.byType(ProductDetailPage),
        matchesGoldenFile('../../goldens/products_detail_$tag.png'),
      );
    });

    testWidgets('product form golden · $tag', (tester) async {
      sizeToPhone(tester);
      await pumpLocalizedApp(
        tester,
        host(const ProductFormPage(), theme, _DetailRepository()),
      );
      await expectLater(
        find.byType(ProductFormPage),
        matchesGoldenFile('../../goldens/products_form_$tag.png'),
      );
    });
  }
}

class _ListRepository extends FakeProductRepository {
  _ListRepository() : super(latency: Duration.zero);

  @override
  Future<PagedProducts> getProducts({
    required String storeId,
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async => PagedProducts(items: [_milk], hasMore: false);
}

class _DetailRepository extends FakeProductRepository {
  _DetailRepository() : super(latency: Duration.zero);

  @override
  Future<ProductEntity> getProduct(String id, {required String storeId}) async => _milk;

  @override
  Future<List<StoreHolding>> getHoldings(String productId) async => [
    StoreHolding(
      storeId: 'store-b',
      storeName: 'Northside · Second',
      remaining: Decimal.parse('4'),
      latestUnitPrice: Decimal.parse('1.30'),
    ),
  ];
}
