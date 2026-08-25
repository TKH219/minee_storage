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
import 'package:mine_storage/features/products/pages/product_list_page.dart';
import 'package:mine_storage/features/products/scan/pages/scan_page.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/loaders/loaders.dart';
import 'package:mine_storage/shared/ui/product_row.dart';

import '../../support/localization_test_harness.dart';

/// Every animation freezes to a poster frame under reduced motion, and the
/// screen still has to read complete with nothing moving.
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
    child: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Theme(data: AppTheme.light(), child: child),
    ),
  );

  testWidgets('the scanner still reads complete when the sweep is frozen', (tester) async {
    await pumpLocalizedApp(tester, host(const ScanPage()), settle: false);

    // Frozen, not gone: the viewfinder is still there to aim with.
    expect(find.byType(ScanSweep), findsOneWidget);
    expect(find.text('Scan a barcode'), findsWidgets);

    // Nothing is scheduling frames, so neither of these may time out.
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const Key('scan-manual-field')),
      200,
      scrollable: find.byType(Scrollable).first,
    );

    // The escape hatch is reachable with the camera frozen.
    expect(find.byKey(const Key('scan-manual-field')), findsOneWidget);
  });

  testWidgets('the list still reads complete with no shimmer', (tester) async {
    await pumpLocalizedApp(tester, host(const ProductListPage()));

    expect(find.byType(ProductRow), findsOneWidget);
    expect(find.text('Whole Milk 1L'), findsOneWidget);
  });
}

final _milk = ProductEntity(
  id: 'p1',
  name: 'Whole Milk 1L',
  unit: ProductUnit.litre,
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
}
