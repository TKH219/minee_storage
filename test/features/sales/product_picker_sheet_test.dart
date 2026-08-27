import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_sale_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/new/widgets/product_picker_sheet.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

final today = DateTime(2026, 8, 26);

void main() {
  late FakeProductRepository products;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    products = FakeProductRepository(latency: Duration.zero);
  });

  Future<ProductEntity?> picked = Future.value();

  Future<void> pumpPicker(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await initLocalization();
    useLocale(locale);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          productRepositoryProvider.overrideWithValue(products),
          saleRepositoryProvider.overrideWithValue(
            FakeSaleRepository(products, latency: Duration.zero),
          ),
          activeStoreProvider.overrideWith(() => FixedActiveStore('store-a')),
          nowProvider.overrideWithValue(() => today),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => picked = showProductPicker(context),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('opens on the full list with the search beside a scan button',
      (tester) async {
    await pumpPicker(tester);

    expect(find.text('Search your products'), findsOneWidget);
    expect(find.byKey(const Key('picker-scan-button')), findsOneWidget);
    expect(find.textContaining('ALL PRODUCTS · 3'), findsOneWidget);
    expect(find.text('Olive oil 1L'), findsOneWidget);
  });

  testWidgets('picking an in-stock product returns it and closes', (tester) async {
    await pumpPicker(tester);

    await tester.tap(find.byKey(const Key('picker-row-p1')));
    await tester.pumpAndSettle();

    expect(find.text('Search your products'), findsNothing);
    expect((await picked)?.id, 'p1');
  });

  group('out of stock', () {
    setUp(() async {
      products = FakeProductRepository(latency: Duration.zero);
      await products.applyLedgerDeltas(
        'p3',
        [BatchAllocation(batchId: 'b4', quantity: d('2'))],
        storeId: 'store-a',
      );
    });

    testWidgets('is visible, badged, and dimmed to 60%', (tester) async {
      await pumpPicker(tester);

      expect(find.byKey(const Key('picker-row-p3')), findsOneWidget);
      expect(find.text('Out of stock'), findsOneWidget);

      final opacity = tester.widget<Opacity>(
        find.ancestor(
          of: find.byKey(const Key('picker-row-p3')),
          matching: find.byType(Opacity),
        ),
      );
      expect(opacity.opacity, 0.6);
    });

    testWidgets('cannot be added by tapping it', (tester) async {
      await pumpPicker(tester);

      await tester.tap(find.byKey(const Key('picker-row-p3')));
      await tester.pumpAndSettle();

      expect(
        find.text('Search your products'),
        findsOneWidget,
        reason: 'the sheet must stay open — nothing was picked',
      );
    });

    testWidgets('says outright why it cannot be added', (tester) async {
      await pumpPicker(tester);

      expect(
        find.textContaining('there is no negative stock'),
        findsOneWidget,
      );
    });
  });

  testWidgets('searching narrows the list', (tester) async {
    await pumpPicker(tester);

    await tester.enterText(find.byType(TextField), 'milk');
    await tester.pumpAndSettle();

    expect(find.text('Whole milk 1L'), findsOneWidget);
    expect(find.text('Olive oil 1L'), findsNothing);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpPicker(tester, locale: viLocale);

    expect(find.text('Tìm sản phẩm của bạn'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpPicker(tester, brightness: Brightness.dark);

    expect(find.text('Search your products'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
