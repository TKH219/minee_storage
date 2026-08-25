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
import 'package:mine_storage/features/products/scan/pages/scan_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

/// An unresolved key renders as its own path — `products.addPhoto` rather than
/// "Add a photo". Nothing user-visible may look like that in either language.
final _looksLikeAKey = RegExp(r'^[a-z][a-zA-Z]*(\.[a-zA-Z]+)+$');

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    prefs = await SharedPreferences.getInstance();
  });

  Widget host(Widget child) => ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      productRepositoryProvider.overrideWithValue(_Repository()),
      nowProvider.overrideWithValue(() => DateTime(2026, 8, 20)),
    ],
    child: Theme(data: AppTheme.light(), child: child),
  );

  void expectNoRawKeys(WidgetTester tester) {
    final leaked = tester
        .widgetList<Text>(find.byType(Text))
        .map((text) => text.data)
        .whereType<String>()
        .where(_looksLikeAKey.hasMatch)
        .toList();

    expect(leaked, isEmpty, reason: 'these keys were never translated: $leaked');
  }

  for (final (locale, tag) in [(enLocale, 'en'), (viLocale, 'vi')]) {
    testWidgets('the product list renders no raw keys · $tag', (tester) async {
      await pumpLocalizedApp(tester, host(const ProductListPage()), locale: locale);
      expectNoRawKeys(tester);
    });

    testWidgets('product detail renders no raw keys · $tag', (tester) async {
      await pumpLocalizedApp(
        tester,
        host(const ProductDetailPage(productId: 'p1')),
        locale: locale,
      );
      expectNoRawKeys(tester);
    });

    testWidgets('the product form renders no raw keys · $tag', (tester) async {
      await pumpLocalizedApp(tester, host(const ProductFormPage()), locale: locale);
      expectNoRawKeys(tester);
    });

    testWidgets('the scanner renders no raw keys · $tag', (tester) async {
      // The scan sweep animates forever, so this one must not settle.
      await pumpLocalizedApp(
        tester,
        host(const ScanPage()),
        locale: locale,
        settle: false,
      );
      expectNoRawKeys(tester);
    });
  }

  testWidgets('the whole product feature really does translate', (tester) async {
    await pumpLocalizedApp(tester, host(const ProductFormPage()), locale: viLocale);

    // A Vietnamese string that only exists if the file was actually consulted.
    expect(find.text('Đây là gì?'), findsOneWidget);
  });
}

final _milk = ProductEntity(
  id: 'p1',
  name: 'Whole Milk 1L',
  unit: ProductUnit.litre,
  brand: 'Dairyland',
  createdAt: DateTime(2026, 8, 1),
  updatedAt: DateTime(2026, 8, 8),
  batches: [
    ProductBatchEntity(
      id: 'b1',
      productId: 'p1',
      storeId: 'store-a',
      batchCode: '#B-0001',
      purchasedAt: DateTime(2026, 8, 8),
      unitPrice: Decimal.parse('1.10'),
      expiryDate: DateTime(2026, 8, 22),
      initialQuantity: Decimal.parse('12'),
      remainingQuantity: Decimal.parse('2'),
      createdAt: DateTime(2026, 8, 8),
      updatedAt: DateTime(2026, 8, 8),
    ),
  ],
);

class _Repository extends FakeProductRepository {
  _Repository() : super(latency: Duration.zero);

  @override
  Future<PagedProducts> getProducts({
    required String storeId,
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async => PagedProducts(items: [_milk], hasMore: false);

  @override
  Future<ProductEntity> getProduct(String id, {required String storeId}) async => _milk;

  @override
  Future<List<StoreHolding>> getHoldings(String productId) async => [
    StoreHolding(
      storeId: 'store-b',
      storeName: 'Second shop',
      remaining: Decimal.parse('4'),
    ),
  ];
}
