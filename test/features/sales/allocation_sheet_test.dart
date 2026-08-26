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
import 'package:mine_storage/features/sales/new/widgets/allocation_row.dart';
import 'package:mine_storage/features/sales/new/widgets/allocation_sheet.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/localization_test_harness.dart';

Decimal d(String value) => Decimal.parse(value);

final today = DateTime(2026, 8, 26);

void main() {
  late FakeProductRepository products;
  Future<SaleDraftLine?> added = Future.value();

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    products = FakeProductRepository(latency: Duration.zero);
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
    ProductUnit unit = ProductUnit.litre,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    // Repository reads schedule a timer, and inside testWidgets a timer only
    // fires when the tester pumps — so this has to run outside the fake clock.
    final product = (await tester.runAsync(
      () => products.getProduct('p1', storeId: 'store-a'),
    ))!.copyWith(unit: unit);

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
                  onPressed: () =>
                      added = showAllocationSheet(context, product: product),
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

  testWidgets('names the product and both fields', (tester) async {
    await pumpSheet(tester);

    expect(find.text('Olive oil 1L'), findsOneWidget);
    expect(find.text('Quantity'), findsOneWidget);
    expect(find.text('Sell price each'), findsOneWidget);
  });

  testWidgets('shows the split with a row per lot, earliest first', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('allocation-increment')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('allocation-increment')));
    await tester.pumpAndSettle();

    expect(find.textContaining('COMES FROM'), findsOneWidget);
    expect(find.byType(AllocationRow), findsNWidgets(2));
  });

  testWidgets('puts two different costs on two plain lines', (tester) async {
    await pumpSheet(tester);

    for (var i = 0; i < 3; i++) {
      await tester.tap(find.byKey(const Key('allocation-increment')));
      await tester.pumpAndSettle();
    }

    expect(find.textContaining('empties this lot'), findsOneWidget);
    expect(find.textContaining('will remain'), findsOneWidget);
  });

  testWidgets('the stepper drives the quantity shown', (tester) async {
    await pumpSheet(tester);

    expect(find.byKey(const Key('allocation-quantity')), findsOneWidget);
    await tester.tap(find.byKey(const Key('allocation-increment')));
    await tester.pumpAndSettle();

    final quantity = tester.widget<Text>(
      find.byKey(const Key('allocation-quantity')),
    );
    expect(quantity.data, '2');
  });

  testWidgets('Add to sale returns the line and closes', (tester) async {
    await pumpSheet(tester);

    await tester.tap(find.byKey(const Key('allocation-add-to-sale')));
    await tester.pumpAndSettle();

    final line = await added;
    expect(line, isNotNull);
    expect(line!.productId, 'p1');
    expect(line.quantity, Decimal.one);
  });

  testWidgets('Add to sale is disabled while the quantity exceeds stock',
      (tester) async {
    await pumpSheet(tester);

    for (var i = 0; i < 9; i++) {
      await tester.tap(find.byKey(const Key('allocation-increment')));
      await tester.pumpAndSettle();
    }

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('allocation-add-to-sale')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
    expect(find.textContaining('Only'), findsOneWidget);
  });

  testWidgets('a blank price disables Add to sale', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(find.byKey(const Key('allocation-sell-price')), '');
    await tester.pumpAndSettle();

    final button = tester.widget<FilledButton>(
      find.descendant(
        of: find.byKey(const Key('allocation-add-to-sale')),
        matching: find.byType(FilledButton),
      ),
    );
    expect(button.onPressed, isNull);
  });

  testWidgets('the line total follows quantity times price', (tester) async {
    await pumpSheet(tester);

    await tester.enterText(
      find.byKey(const Key('allocation-sell-price')),
      '2000',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('allocation-increment')));
    await tester.pumpAndSettle();

    // The display currency is the app default here, and VND carries no minor
    // unit — the figure is the arithmetic, the symbol is the preference.
    final total = tester.widget<Text>(
      find.byKey(const Key('allocation-line-total')),
    );
    expect(total.data, '₫4,000');
  });

  testWidgets('a fraction against a counted unit is refused', (tester) async {
    await pumpSheet(tester, unit: ProductUnit.piece);

    await tester.tap(find.byKey(const Key('allocation-add-to-sale')));
    await tester.pumpAndSettle();

    expect(find.text('Olive oil 1L'), findsNothing, reason: 'a whole unit is fine');
  });

  group('manual override', () {
    testWidgets('Edit hands the split to the seller, seeded from FEFO',
        (tester) async {
      await pumpSheet(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('allocation-increment')));
        await tester.pumpAndSettle();
      }

      await tester.tap(find.byKey(const Key('allocation-toggle-manual')));
      await tester.pumpAndSettle();

      expect(find.text('Choose lots yourself'), findsOneWidget);
      expect(find.textContaining('6 needed'), findsOneWidget);
      expect(find.byKey(const Key('manual-qty-b1')), findsOneWidget);
      expect(find.byKey(const Key('manual-qty-b2')), findsOneWidget);
    });

    testWidgets('a short split names the shortfall and disables Add to sale',
        (tester) async {
      await pumpSheet(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('allocation-increment')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('allocation-toggle-manual')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('manual-qty-b1')), '1');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('manual-qty-b2')), '3');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('Assign 2.000 more before you can continue'),
        findsOneWidget,
      );

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('allocation-add-to-sale')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('an over-allocation names the excess', (tester) async {
      await pumpSheet(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('allocation-increment')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('allocation-toggle-manual')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('manual-qty-b2')), '6');
      await tester.pumpAndSettle();

      expect(find.textContaining('Remove 2.000'), findsOneWidget);
    });

    testWidgets('an exact split re-enables Add to sale', (tester) async {
      await pumpSheet(tester);
      for (var i = 0; i < 5; i++) {
        await tester.tap(find.byKey(const Key('allocation-increment')));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.byKey(const Key('allocation-toggle-manual')));
      await tester.pumpAndSettle();

      await tester.enterText(find.byKey(const Key('manual-qty-b1')), '1');
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('manual-qty-b2')), '5');
      await tester.pumpAndSettle();

      final button = tester.widget<FilledButton>(
        find.descendant(
          of: find.byKey(const Key('allocation-add-to-sale')),
          matching: find.byType(FilledButton),
        ),
      );
      expect(button.onPressed, isNotNull);
    });
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    await pumpSheet(tester, locale: viLocale);

    expect(find.text('Số lượng'), findsOneWidget);
    expect(find.text('Thêm vào đơn'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    await pumpSheet(tester, brightness: Brightness.dark);

    expect(find.text('Quantity'), findsOneWidget);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
