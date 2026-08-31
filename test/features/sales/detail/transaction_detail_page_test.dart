import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/detail/pages/transaction_detail_page.dart';
import 'package:mine_storage/providers.dart';

import '../../../support/active_store_override.dart';
import '../../../support/design_frame.dart';
import '../../../support/fake_transaction_repository.dart';
import '../../../support/localization_test_harness.dart';
import '../../../support/transaction_fixtures.dart';

/// S26, built against the `#ledger` detail frames. What a movement shows is
/// decided by its type, never by what happens to be non-zero.
void main() {
  late FakeTransactionRepository repository;
  late SharedPreferences preferences;

  setUp(() async {
    repository = FakeTransactionRepository();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpDetail(
    WidgetTester tester, {
    Locale locale = enLocale,
    Brightness brightness = Brightness.light,
  }) async {
    useDesignFrame(tester);
    await initLocalization();
    useLocale(locale);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(preferences),
          transactionRepositoryProvider.overrideWithValue(repository),
          activeStoreProvider.overrideWith(() => FixedActiveStore('store-1')),
        ],
        child: MaterialApp(
          theme: brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
          home: const TransactionDetailPage(transactionId: 'txn-1'),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('a sale names every lot it drew from, with the cost frozen', (
    tester,
  ) async {
    repository.nextById = ledgerTransaction(
      counterparty: 'Corner Café',
      lines: [
        ledgerLine(batchCode: 'L-2608-A', quantityDelta: '-2.000', unitCostSnapshot: '1.10'),
        ledgerLine(
          id: 'line-2',
          batchId: 'batch-2',
          batchCode: 'L-2608-B',
          quantityDelta: '-4.000',
          unitCostSnapshot: '1.25',
        ),
      ],
    );

    await pumpDetail(tester);

    expect(find.text('S-202608-0041'), findsOneWidget);
    expect(find.text('Corner Café'), findsOneWidget);
    expect(find.textContaining('L-2608-A'), findsOneWidget);
    expect(find.textContaining('L-2608-B'), findsOneWidget);
    expect(find.byKey(const Key('detail-net-profit')), findsOneWidget);
  });

  testWidgets('a receive shows the supplier and no profit row at all', (tester) async {
    repository.nextById = ledgerTransaction(
      code: 'R-202608-0018',
      type: TransactionType.receive,
      counterparty: 'Dairyland',
      paymentMethod: PaymentMethod.bankTransfer,
      fees: [ledgerFee(name: 'Freight', direction: FeeDirection.buyerCharge)],
    );

    await pumpDetail(tester);

    expect(find.text('Dairyland'), findsOneWidget);
    expect(find.text('Freight'), findsWidgets);
    // A delivery has no revenue to measure profit against, so the row is
    // absent rather than zero.
    expect(find.byKey(const Key('detail-net-profit')), findsNothing);
  });

  testWidgets('a write-off shows its reason and the value that left', (tester) async {
    repository.nextById = ledgerTransaction(
      code: 'W-202608-0007',
      type: TransactionType.writeOff,
      reason: WriteOffReason.expired,
      paymentMethod: null,
      reasonNote: 'Found swollen during the cold-room check',
      lines: [
        ledgerLine(quantityDelta: '-3.000', unitCostSnapshot: '2.40', lineCost: '7.20'),
      ],
    );

    await pumpDetail(tester);

    expect(find.text('Expired'), findsOneWidget);
    expect(find.text('What left stock'), findsOneWidget);
    expect(find.text('Value lost'), findsOneWidget);
    expect(find.byKey(const Key('detail-net-profit')), findsNothing);
  });

  testWidgets('a stock count shows the signed delta it applied', (tester) async {
    repository.nextById = ledgerTransaction(
      code: 'A-202608-0003',
      type: TransactionType.adjust,
      paymentMethod: null,
      reasonNote: 'Two cartons crushed',
      lines: [ledgerLine(quantityDelta: '-2.000', lineCost: '0.00')],
    );

    await pumpDetail(tester);

    expect(find.text('Lot counted'), findsOneWidget);
    expect(find.text('-2.000'), findsWidgets);
    expect(find.text('Two cartons crushed'), findsOneWidget);
  });

  testWidgets('a stock count draws what was counted against what was held', (
    tester,
  ) async {
    repository.nextById = ledgerTransaction(
      code: 'A-202608-0003',
      type: TransactionType.adjust,
      paymentMethod: null,
      reasonNote: 'Two cartons crushed',
      lines: [
        ledgerLine(
          quantityBefore: '12.000',
          quantityDelta: '-2.000',
          lineCost: '0.00',
        ),
      ],
    );

    await pumpDetail(tester);

    expect(find.text('Counted'), findsOneWidget);
    expect(find.text('Previously'), findsOneWidget);
    expect(find.text('Difference'), findsOneWidget);
    expect(find.text('10.000'), findsWidgets);
    expect(find.text('12.000'), findsWidgets);

    expect(find.text('System held'), findsOneWidget);
    expect(find.text('Counted on the shelf'), findsOneWidget);
    expect(find.text('Applied delta'), findsOneWidget);
  });

  testWidgets('a stock count with no recorded holding keeps the delta header', (
    tester,
  ) async {
    repository.nextById = ledgerTransaction(
      code: 'A-202608-0003',
      type: TransactionType.adjust,
      paymentMethod: null,
      lines: [ledgerLine(quantityDelta: '-2.000', lineCost: '0.00')],
    );

    await pumpDetail(tester);

    expect(find.text('Counted'), findsNothing);
    expect(find.text('Previously'), findsNothing);
    expect(find.text('Applied delta'), findsWidgets);
  });

  testWidgets('a write-off names what the lot held before it left', (tester) async {
    repository.nextById = ledgerTransaction(
      code: 'W-202608-0007',
      type: TransactionType.writeOff,
      reason: WriteOffReason.expired,
      paymentMethod: null,
      lines: [
        ledgerLine(
          quantityBefore: '3.000',
          quantityDelta: '-3.000',
          unitCostSnapshot: '2.40',
          lineCost: '7.20',
        ),
      ],
    );

    await pumpDetail(tester);

    expect(find.text('of 3.000 held'), findsOneWidget);
  });

  testWidgets('an edited movement carries its marker', (tester) async {
    repository.nextById = ledgerTransaction(amendedAt: DateTime(2026, 8, 26, 14, 2));

    await pumpDetail(tester);

    expect(find.byKey(const Key('transaction-edited-notice')), findsOneWidget);
  });

  testWidgets('a lot re-costed since the sale is flagged where the two figures sit', (
    tester,
  ) async {
    repository.nextById = ledgerTransaction(
      lines: [ledgerLine(unitCostSnapshot: '1.10', batchUnitCost: '1.30')],
    );

    await pumpDetail(tester);

    expect(find.byKey(const Key('cost-moved-line-1')), findsOneWidget);
  });

  testWidgets('the delete dialog names what returns to each lot', (tester) async {
    repository.nextById = ledgerTransaction(
      lines: [
        ledgerLine(batchCode: 'L-2608-A', quantityDelta: '-2.000'),
        ledgerLine(
          id: 'line-2',
          batchId: 'batch-2',
          batchCode: 'L-2608-B',
          quantityDelta: '-4.000',
        ),
      ],
    );
    await pumpDetail(tester);

    await tester.tap(find.byKey(const Key('transaction-delete-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('transaction-delete-dialog')), findsOneWidget);
    expect(find.text('L-2608-A · Whole Milk 1L'), findsOneWidget);
    expect(find.text('+2.000'), findsOneWidget);
    expect(find.text('+4.000'), findsOneWidget);
  });

  testWidgets('a refused reversal names the shortfall and changes nothing', (
    tester,
  ) async {
    repository.nextById = ledgerTransaction();
    await pumpDetail(tester);
    repository.failWith = ReversalBlockedException(
      batchCode: 'L-2608-A',
      remaining: dec('0'),
      shortfall: dec('2.000'),
    );

    await tester.tap(find.byKey(const Key('transaction-delete-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('transaction-delete-confirm')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('reversal-refused')), findsOneWidget);
    expect(find.text('Shortfall'), findsOneWidget);
    expect(find.text('S-202608-0041'), findsOneWidget);
  });
}
