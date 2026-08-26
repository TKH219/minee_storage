import 'package:decimal/decimal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/list/pages/sales_list_page.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_row.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../support/active_store_override.dart';
import '../../support/design_frame.dart';
import '../../support/fake_transaction_repository.dart';
import '../../support/localization_test_harness.dart';

/// S25, built against the `#ledger` frames. Four movement types in one list,
/// grouped by day, with each header carrying that day's net money.
void main() {
  Decimal d(String value) => Decimal.parse(value);

  Transaction txn({
    required String code,
    TransactionType type = TransactionType.sale,
    String buyerTotal = '38.73',
    String delta = '-8.000',
    String? counterparty,
    bool amended = false,
  }) => Transaction(
    id: code,
    storeId: 'store-1',
    type: type,
    code: code,
    occurredAt: DateTime(2026, 8, 21, 9, 12),
    counterparty: counterparty,
    amendedAt: amended ? DateTime(2026, 8, 22) : null,
    paymentMethod: type.carriesMoney ? PaymentMethod.cash : null,
    reason: type == TransactionType.writeOff ? WriteOffReason.expired : null,
    lines: [
      TransactionLine(
        id: '$code-l1',
        transactionId: code,
        productId: 'p-1',
        batchId: 'b-1',
        batchCode: '#B-0001',
        productName: 'Whole Milk 1L',
        unit: ProductUnit.litre,
        quantityDelta: d(delta),
        unitPrice: d('4.84'),
        unitCostSnapshot: d('2.50'),
        lineGross: d(buyerTotal),
        lineCost: d('20.00'),
      ),
    ],
    money: TransactionMoney(
      itemsSubtotal: d(buyerTotal),
      discountTotal: Decimal.zero,
      buyerChargeTotal: Decimal.zero,
      sellerCostTotal: Decimal.zero,
      passThroughTotal: Decimal.zero,
      buyerTotal: d(buyerTotal),
      netRevenue: d(buyerTotal),
      cogs: d('20.00'),
      grossProfit: Decimal.zero,
      netProfit: Decimal.zero,
      netMargin: Decimal.zero,
    ),
    updatedTime: DateTime(2026, 8, 21, 9, 12),
  );

  late FakeTransactionRepository repository;
  late SharedPreferences preferences;

  setUp(() async {
    repository = FakeTransactionRepository();
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
  });

  Future<void> pumpLedger(
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
          home: const SalesListPage(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  void seedOneDay() {
    repository.nextPage = TransactionPage(
      page: 1,
      limit: 20,
      total: 3,
      days: [
        TransactionDay(
          date: DateTime(2026, 8, 21),
          subtotal: d('-37.07'),
          transactionCount: 3,
          transactions: [
            txn(code: 'S-202608-0041', counterparty: 'Corner Café'),
            txn(
              code: 'R-202608-0018',
              type: TransactionType.receive,
              buyerTotal: '88.00',
              delta: '44.000',
              counterparty: 'Dairyland',
            ),
            txn(
              code: 'W-202608-0007',
              type: TransactionType.writeOff,
              buyerTotal: '0.00',
              delta: '-3.000',
            ),
          ],
        ),
      ],
    );
  }

  testWidgets('four movement types read as one list', (tester) async {
    seedOneDay();
    await pumpLedger(tester);

    expect(find.text('S-202608-0041'), findsOneWidget);
    expect(find.text('R-202608-0018'), findsOneWidget);
    expect(find.text('W-202608-0007'), findsOneWidget);
  });

  testWidgets('the day header carries the net figure the server computed', (tester) async {
    seedOneDay();
    await pumpLedger(tester);

    // Negative because the day's delivery cost more than its sales took. The
    // figure is the server's own: nothing here sums the three visible rows,
    // which would print a different number once the day spans two pages.
    final header = tester.widget<LedgerDayHeader>(find.byType(LedgerDayHeader));
    expect(header.day.subtotal, d('-37.07'));
    expect(find.textContaining('-'), findsWidgets);
  });

  testWidgets('the arrow follows the sign of the delta, never the type', (tester) async {
    seedOneDay();
    await pumpLedger(tester);

    // A delivery adds stock and a sale removes it, so both arrows appear.
    expect(find.byIcon(Icons.arrow_upward_rounded), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward_rounded), findsNWidgets(2));
  });

  testWidgets('a stock count shows a dash rather than a zero', (tester) async {
    repository.nextPage = TransactionPage(
      page: 1,
      limit: 20,
      total: 1,
      days: [
        TransactionDay(
          date: DateTime(2026, 8, 21),
          subtotal: Decimal.zero,
          transactionCount: 1,
          transactions: [
            txn(
              code: 'A-202608-0003',
              type: TransactionType.adjust,
              buyerTotal: '0.00',
              delta: '-2.000',
            ),
          ],
        ),
      ],
    );
    await pumpLedger(tester);

    expect(find.text('—'), findsOneWidget);
  });

  testWidgets('an amended movement says so', (tester) async {
    repository.nextPage = TransactionPage(
      page: 1,
      limit: 20,
      total: 1,
      days: [
        TransactionDay(
          date: DateTime(2026, 8, 21),
          subtotal: d('19.40'),
          transactionCount: 1,
          transactions: [txn(code: 'S-202608-0040', amended: true)],
        ),
      ],
    );
    await pumpLedger(tester);

    expect(find.text('Edited'), findsOneWidget);
  });

  testWidgets('nothing recorded is the first-run state, not an error', (tester) async {
    repository.nextPage = const TransactionPage(days: [], page: 1, limit: 20, total: 0);
    await pumpLedger(tester);

    expect(find.byType(EmptyView), findsOneWidget);
    expect(find.text('Nothing recorded yet'), findsOneWidget);
    // The tab now explains itself rather than admitting it is unbuilt.
    expect(find.textContaining('not built yet'), findsNothing);
  });

  testWidgets('renders in Vietnamese without leaking a key', (tester) async {
    seedOneDay();
    await pumpLedger(tester, locale: viLocale);

    expect(find.text('Bán hàng'), findsWidgets);
    expect(find.textContaining('sales.'), findsNothing);
  });

  testWidgets('renders in dark without leaking a key', (tester) async {
    seedOneDay();
    await pumpLedger(tester, brightness: Brightness.dark);

    expect(find.text('Sales'), findsWidgets);
    expect(find.textContaining('sales.'), findsNothing);
  });
}
