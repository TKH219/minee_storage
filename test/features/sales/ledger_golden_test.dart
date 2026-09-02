import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/clock.dart';
import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/detail/pages/transaction_detail_page.dart';
import 'package:mine_storage/features/sales/list/pages/sales_list_page.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_transaction_repository.dart';
import '../../support/localization_test_harness.dart';
import '../../support/transaction_fixtures.dart';

/// The ledger and one movement read back, against `22-ledger/{light,dark}`.
void main() {
  late FakeTransactionRepository repository;

  setUp(() {
    repository = FakeTransactionRepository();
  });

  Future<void> pump(
    WidgetTester tester,
    Widget screen, {
    required Brightness brightness,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    useDesignFrame(tester);
    await initLocalization();
    useLocale();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          transactionRepositoryProvider.overrideWithValue(repository),
          activeStoreProvider.overrideWith(() => FixedActiveStore('store-1')),
          nowProvider.overrideWithValue(() => DateTime(2026, 8, 26)),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: screen,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void seedLedger() {
    repository.nextPage = TransactionPage(
      page: 1,
      limit: 20,
      total: 4,
      days: [
        TransactionDay(
          date: DateTime(2026, 8, 26),
          subtotal: Decimal.parse('-37.07'),
          transactionCount: 3,
          transactions: [
            ledgerTransaction(
              counterparty: 'Corner Café',
              occurredAt: DateTime(2026, 8, 26, 9, 12),
              money: ledgerMoney(buyerTotal: '38.73'),
            ),
            ledgerTransaction(
              id: 'txn-2',
              code: 'R-202608-0018',
              type: TransactionType.receive,
              counterparty: 'Dairyland',
              occurredAt: DateTime(2026, 8, 26, 8, 40),
              money: ledgerMoney(buyerTotal: '88.00'),
              lines: [ledgerLine(id: 'line-r', quantityDelta: '44.000')],
            ),
            ledgerTransaction(
              id: 'txn-3',
              code: 'W-202608-0007',
              type: TransactionType.writeOff,
              paymentMethod: null,
              reason: WriteOffReason.expired,
              occurredAt: DateTime(2026, 8, 26, 8, 5),
              money: ledgerMoney(buyerTotal: '0.00', netRevenue: '0.00', cogs: '7.20'),
              lines: [ledgerLine(id: 'line-w', quantityDelta: '-3.000')],
            ),
          ],
        ),
        TransactionDay(
          date: DateTime(2026, 8, 25),
          subtotal: Decimal.parse('24.10'),
          transactionCount: 1,
          transactions: [
            ledgerTransaction(
              id: 'txn-4',
              code: 'A-202608-0003',
              type: TransactionType.adjust,
              paymentMethod: null,
              occurredAt: DateTime(2026, 8, 25, 18, 30),
              money: ledgerMoney(buyerTotal: '0.00', netRevenue: '0.00', cogs: '0.00'),
              lines: [ledgerLine(id: 'line-a', quantityDelta: '-2.000')],
            ),
          ],
        ),
      ],
    );
  }

  for (final (brightness, tag) in [
    (Brightness.light, 'light'),
    (Brightness.dark, 'dark'),
  ]) {
    testWidgets('ledger list golden · $tag', (tester) async {
      seedLedger();
      await pump(tester, const SalesListPage(), brightness: brightness);
      await expectLater(
        find.byType(SalesListPage),
        matchesGoldenFile('../../goldens/ledger_list_$tag.png'),
      );
    });

    testWidgets('transaction detail golden · $tag', (tester) async {
      repository.nextById = ledgerTransaction(
        counterparty: 'Corner Café',
        lines: [
          ledgerLine(batchCode: 'L-2608-A', quantityDelta: '-2.000'),
          ledgerLine(
            id: 'line-2',
            batchId: 'batch-2',
            batchCode: 'L-2608-B',
            quantityDelta: '-4.000',
            unitCostSnapshot: '1.25',
          ),
        ],
      );
      await pump(
        tester,
        const TransactionDetailPage(transactionId: 'txn-1'),
        brightness: brightness,
      );
      await expectLater(
        find.byType(TransactionDetailPage),
        matchesGoldenFile('../../goldens/ledger_detail_$tag.png'),
      );
    });
  }
}
