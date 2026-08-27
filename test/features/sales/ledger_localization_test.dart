import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/widgets/receive_sheet.dart';
import 'package:mine_storage/features/products/detail/widgets/stock_count_sheet.dart';
import 'package:mine_storage/features/products/detail/widgets/write_off_sheet.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/detail/pages/transaction_detail_page.dart';
import 'package:mine_storage/features/sales/edit/pages/transaction_edit_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_transaction_repository.dart';
import '../../support/localization_test_harness.dart';
import '../../support/raw_key_matcher.dart';
import '../../support/transaction_fixtures.dart';

/// Every screen the ledger adds, in both languages and both modes, with one
/// rule: nothing may reach the user as a raw translation key.
void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository();
  });

  Future<void> pumpScreen(
    WidgetTester tester,
    Widget screen, {
    required Locale locale,
    required Brightness brightness,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);
    await initLocalization();
    useLocale(locale);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionRepositoryProvider.overrideWithValue(repository),
          productRepositoryProvider.overrideWithValue(
            FakeProductRepository(latency: Duration.zero),
          ),
          activeStoreProvider.overrideWith(() => FixedActiveStore('store-1')),
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 26)),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: Scaffold(body: screen),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ProductEntity product() => ProductEntity(
    id: 'product-1',
    name: 'Greek Yoghurt 500g',
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    batches: [
      ProductBatchEntity(
        id: 'batch-1',
        productId: 'product-1',
        storeId: 'store-1',
        batchCode: 'L-2508-C',
        purchasedAt: DateTime(2026, 8, 1),
        unitPrice: dec('2.40'),
        expiryDate: DateTime(2026, 9, 14),
        initialQuantity: dec('20.000'),
        remainingQuantity: dec('3.000'),
        createdAt: DateTime(2026, 8, 1),
        updatedAt: DateTime(2026, 8, 1),
      ),
    ],
  );

  for (final locale in [enLocale, viLocale]) {
    for (final brightness in [Brightness.light, Brightness.dark]) {
      final tag = '${locale.languageCode} · ${brightness.name}';

      for (final type in TransactionType.values) {
        testWidgets('${type.name} detail renders no raw key · $tag', (tester) async {
          repository.nextById = ledgerTransaction(
            type: type,
            paymentMethod: type.carriesMoney ? PaymentMethod.card : null,
            reason: type == TransactionType.writeOff ? WriteOffReason.expired : null,
            reasonNote: type.carriesMoney ? null : 'Two cartons crushed',
            counterparty: type == TransactionType.receive ? 'Dairyland' : null,
            amendedAt: DateTime(2026, 8, 26, 14, 2),
            fees: type == TransactionType.sale
                ? [ledgerFee(name: 'VAT 8%', direction: FeeDirection.passThrough)]
                : const [],
            lines: [ledgerLine(unitCostSnapshot: '1.10', batchUnitCost: '1.30')],
          );

          await pumpScreen(
            tester,
            const TransactionDetailPage(transactionId: 'txn-1'),
            locale: locale,
            brightness: brightness,
          );
          expectNoRawKeys(tester);
        });
      }

      testWidgets('amend renders no raw key · $tag', (tester) async {
        repository.nextById = ledgerTransaction();
        await pumpScreen(
          tester,
          const TransactionEditPage(transactionId: 'txn-1'),
          locale: locale,
          brightness: brightness,
        );
        expectNoRawKeys(tester);
      });

      testWidgets('write-off sheet renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          WriteOffSheet(product: product()),
          locale: locale,
          brightness: brightness,
        );
        expectNoRawKeys(tester);
      });

      testWidgets('stock count sheet renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          StockCountSheet(product: product()),
          locale: locale,
          brightness: brightness,
        );
        expectNoRawKeys(tester);
      });

      testWidgets('receive sheet renders no raw key · $tag', (tester) async {
        await pumpScreen(
          tester,
          ReceiveSheet(product: product()),
          locale: locale,
          brightness: brightness,
        );
        expectNoRawKeys(tester);
      });
    }
  }
}
