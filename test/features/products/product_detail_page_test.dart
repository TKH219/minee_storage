import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/onboarding/onboarding_resolver.dart';
import 'package:mine_storage/features/products/detail/pages/product_detail_page.dart';
import 'package:mine_storage/features/products/detail/widgets/other_stores_section.dart';
import 'package:mine_storage/shared/ui/lot_card.dart';
import 'package:mine_storage/providers.dart';

import '../../support/localization_test_harness.dart';

ProductBatchEntity batch({
  required String id,
  required String code,
  String? expiry,
  String purchased = '2026-08-01',
  String price = '1.10',
  String remaining = '2',
}) {
  return ProductBatchEntity(
    id: id,
    productId: 'p1',
    storeId: 'store-a',
    batchCode: code,
    purchasedAt: DateTime.parse(purchased),
    unitPrice: Decimal.parse(price),
    expiryDate: expiry == null ? null : DateTime.parse(expiry),
    initialQuantity: Decimal.parse('12'),
    remainingQuantity: Decimal.parse(remaining),
    createdAt: DateTime.parse(purchased),
    updatedAt: DateTime.parse(purchased),
  );
}

void main() {
  late SharedPreferences preferences;

  setUp(() async {
    useLocale();
    SharedPreferences.setMockInitialValues({
      OnboardingResolver.activeStoreKey: 'store-a',
    });
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pump(WidgetTester tester, _StubRepository repository) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          productRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: const ProductDetailPage(productId: 'p1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the three derived figures and a card per lot', (tester) async {
    await pump(
      tester,
      _StubRepository(
        product: _product([
          batch(id: 'b1', code: '#B-0001', expiry: '2026-09-01', remaining: '2'),
          batch(id: 'b2', code: '#B-0002', expiry: '2026-12-01', remaining: '8', price: '1.25'),
        ]),
      ),
    );

    expect(find.text('Remaining'), findsWidgets);
    expect(find.text('Nearest expiry'), findsOneWidget);
    expect(find.text('Latest price'), findsOneWidget);
    expect(find.text('10.000'), findsOneWidget);
    expect(find.byType(LotCard), findsNWidgets(2));
  });

  testWidgets('the earliest-expiring lot carries NEXT OUT, and only it', (tester) async {
    await pump(
      tester,
      _StubRepository(
        product: _product([
          batch(id: 'later', code: '#B-0002', expiry: '2026-12-01', remaining: '8'),
          batch(id: 'sooner', code: '#B-0001', expiry: '2026-09-01', remaining: '2'),
        ]),
      ),
    );

    expect(find.text('NEXT OUT'), findsOneWidget);
    final cards = tester.widgetList<LotCard>(find.byType(LotCard)).toList();
    expect(cards.first.isNextOut, isTrue);
    expect(cards.last.isNextOut, isFalse);
  });

  testWidgets('a depleted product cannot be written off and reads a dash', (tester) async {
    await pump(
      tester,
      _StubRepository(product: _product([batch(id: 'b1', code: '#B-0001', remaining: '0')])),
    );

    final writeOff = tester.widget<FilledButton>(
      find.byKey(const Key('write-off-button')),
    );
    final count = tester.widget<OutlinedButton>(
      find.byKey(const Key('count-stock-button')),
    );
    expect(writeOff.onPressed, isNull);
    expect(count.onPressed, isNull);
    expect(find.text('—'), findsWidgets);
  });

  testWidgets('an archived product shows its banner and offers restore', (tester) async {
    await pump(
      tester,
      _StubRepository(
        product: _product(
          [batch(id: 'b1', code: '#B-0001', expiry: '2026-12-01')],
          deletedAt: DateTime.parse('2026-08-20'),
        ),
      ),
    );

    expect(find.byKey(const Key('archived-banner')), findsOneWidget);
    expect(find.byKey(const Key('restore-button')), findsOneWidget);
    expect(find.byKey(const Key('archive-button')), findsNothing);
  });

  testWidgets('other shops holding the product expand on demand', (tester) async {
    await pump(
      tester,
      _StubRepository(
        product: _product([batch(id: 'b1', code: '#B-0001', expiry: '2026-12-01')]),
        holdings: [
          StoreHolding(
            storeId: 'store-a',
            storeName: 'Shop One',
            remaining: Decimal.parse('2'),
          ),
          StoreHolding(
            storeId: 'store-b',
            storeName: 'Shop Two',
            remaining: Decimal.parse('4'),
            latestUnitPrice: Decimal.parse('9.99'),
          ),
        ],
      ),
    );

    expect(find.byType(OtherStoresSection), findsOneWidget);
    // Collapsed: the other shop is named only once opened.
    expect(find.text('Shop Two'), findsNothing);

    await tester.tap(find.byKey(const Key('other-stores-header')));
    await tester.pumpAndSettle();

    expect(find.text('Shop Two'), findsOneWidget);
    // The shop being viewed is not "another" shop.
    expect(find.text('Shop One'), findsNothing);
  });

  testWidgets('with no other shops the section stays out of the way', (tester) async {
    await pump(
      tester,
      _StubRepository(
        product: _product([batch(id: 'b1', code: '#B-0001', expiry: '2026-12-01')]),
      ),
    );

    expect(find.byKey(const Key('other-stores-header')), findsNothing);
  });
}

ProductEntity _product(List<ProductBatchEntity> batches, {DateTime? deletedAt}) {
  return ProductEntity(
    id: 'p1',
    name: 'Whole Milk 1L',
    unit: ProductUnit.litre,
    createdAt: DateTime.parse('2026-07-01'),
    updatedAt: DateTime.parse('2026-07-01'),
    deletedAt: deletedAt,
    batches: batches,
  );
}

class _StubRepository extends FakeProductRepository {
  _StubRepository({required this.product, this.holdings})
    : super(latency: Duration.zero);

  ProductEntity product;
  final List<StoreHolding>? holdings;

  @override
  Future<ProductEntity> getProduct(String id, {required String storeId}) async => product;

  @override
  Future<List<StoreHolding>> getHoldings(String productId) async => holdings ?? const [];
}
