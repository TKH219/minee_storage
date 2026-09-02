import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/widgets/receive_sheet.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/list/states/store_currency_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_transaction_repository.dart';
import '../../support/localization_test_harness.dart';

/// The receive fee editor, against the `#stockmove` frame.
///
/// A receive has no seller side — the server refuses `seller_cost` on one — so
/// the "your cost" the frame draws is a buyer charge the shop bears that stays
/// out of stock value, which is exactly a pass-through.
void main() {
  Future<void> pumpReceive(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);
    await initLocalization();
    useLocale(enLocale);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionRepositoryProvider.overrideWithValue(
            FakeTransactionRepository(),
          ),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(latency: Duration.zero),
          ),
          activeStoreProvider.overrideWith(() => FixedActiveStore('store-1')),
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 26)),
          storeCurrencyProvider.overrideWith(
            (ref) async =>
                const Currency(code: 'USD', symbol: r'$', decimals: 2),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: ReceiveSheet(
              product: ProductEntity(
                id: 'product-1',
                name: 'Whole Milk 1L',
                createdAt: DateTime(2026, 8, 1),
                updatedAt: DateTime(2026, 8, 1),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a receive offers into cost, your cost and discount, never a seller cost', (
    tester,
  ) async {
    await pumpReceive(tester);

    await tester.tap(find.byKey(const Key('receive-edit-fees')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('fees-add')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const Key('add-fee-direction')));
    await tester.pumpAndSettle();

    expect(find.text('into cost'), findsWidgets);
    expect(find.text('your cost'), findsWidgets);
    expect(find.text('discount'), findsWidgets);
    expect(find.text('buyer'), findsNothing);
    expect(find.text('pass-through'), findsNothing);
  });

  test('the three directions a receive can carry all survive the server', () {
    const offered = ReceiveSheet.feeDirections;

    expect(offered, contains(FeeDirection.buyerCharge));
    expect(offered, contains(FeeDirection.passThrough));
    expect(offered, contains(FeeDirection.discount));
    expect(offered, isNot(contains(FeeDirection.sellerCost)));
  });
}
