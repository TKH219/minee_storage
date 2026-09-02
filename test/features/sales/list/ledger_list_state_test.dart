import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/base/base_state.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/sales/list/states/ledger_list_state.dart';
import 'package:mine_storage/providers.dart';

import '../../../support/active_store_override.dart';
import '../../../support/fake_transaction_repository.dart';

void main() {
  Decimal d(String value) => Decimal.parse(value);

  Transaction txn({
    required String code,
    TransactionType type = TransactionType.sale,
    String buyerTotal = '10.00',
    DateTime? at,
    bool amended = false,
  }) => Transaction(
    id: code,
    storeId: 'store-1',
    type: type,
    code: code,
    occurredAt: at ?? DateTime(2026, 8, 21, 10),
    amendedAt: amended ? DateTime(2026, 8, 22) : null,
    money: TransactionMoney(
      itemsSubtotal: d(buyerTotal),
      discountTotal: Decimal.zero,
      buyerChargeTotal: Decimal.zero,
      sellerCostTotal: Decimal.zero,
      passThroughTotal: Decimal.zero,
      buyerTotal: d(buyerTotal),
      netRevenue: d(buyerTotal),
      cogs: Decimal.zero,
      grossProfit: Decimal.zero,
      netProfit: Decimal.zero,
      netMargin: Decimal.zero,
    ),
    updatedTime: DateTime(2026, 8, 21, 10),
  );

  TransactionDay day(
    String date, {
    required String subtotal,
    required int wholeDayCount,
    required List<Transaction> rows,
  }) => TransactionDay(
    date: DateTime.parse(date),
    subtotal: d(subtotal),
    transactionCount: wholeDayCount,
    transactions: rows,
  );

  late FakeTransactionRepository repository;
  late ProviderContainer container;

  ProviderContainer build() => ProviderContainer(
    overrides: [
      transactionRepositoryProvider.overrideWithValue(repository),
      activeStoreProvider.overrideWith(() => FixedActiveStore('store-1')),
    ],
  );

  setUp(() {
    repository = FakeTransactionRepository();
    container = build();
    addTearDown(container.dispose);
    container.listen(ledgerListStateProvider, (_, _) {}, fireImmediately: true);
  });

  LedgerListStateNotifier notifier() =>
      container.read(ledgerListStateProvider.notifier);
  LedgerListState state() => container.read(ledgerListStateProvider);

  group('the day subtotal is the server\'s, never the page\'s', () {
    test('a day split across two pages shows the same figure on both', () async {
      repository.nextPage = TransactionPage(
        page: 1,
        limit: 4,
        total: 7,
        days: [
          day(
            '2026-08-21',
            subtotal: '77.90',
            wholeDayCount: 7,
            rows: [txn(code: 'S-1'), txn(code: 'S-2'), txn(code: 'S-3'), txn(code: 'S-4')],
          ),
        ],
      );

      await notifier().loadInitial();
      final firstPageSubtotal = state().days.single.subtotal;

      repository.nextPage = TransactionPage(
        page: 2,
        limit: 4,
        total: 7,
        days: [
          day(
            '2026-08-21',
            subtotal: '77.90',
            wholeDayCount: 7,
            rows: [txn(code: 'S-5'), txn(code: 'S-6'), txn(code: 'S-7')],
          ),
        ],
      );
      await notifier().loadMore();

      expect(firstPageSubtotal, d('77.90'));
      expect(state().days.single.subtotal, d('77.90'));
      expect(
        state().days.single.transactions,
        hasLength(7),
        reason: 'both pages of the day are now loaded, under one header',
      );
    });

    test('a delivery day reads negative', () async {
      repository.nextPage = TransactionPage(
        page: 1,
        limit: 20,
        total: 1,
        days: [
          day(
            '2026-08-10',
            subtotal: '-250.00',
            wholeDayCount: 1,
            rows: [txn(code: 'R-1', type: TransactionType.receive, buyerTotal: '250.00')],
          ),
        ],
      );

      await notifier().loadInitial();

      expect(state().days.single.subtotal, d('-250.00'));
    });
  });

  group('paging', () {
    test('a later page appends under its own day header', () async {
      repository.nextPage = TransactionPage(
        page: 1,
        limit: 2,
        total: 3,
        days: [day('2026-08-21', subtotal: '20.00', wholeDayCount: 2, rows: [txn(code: 'S-1'), txn(code: 'S-2')])],
      );
      await notifier().loadInitial();

      repository.nextPage = TransactionPage(
        page: 2,
        limit: 2,
        total: 3,
        days: [day('2026-08-20', subtotal: '10.00', wholeDayCount: 1, rows: [txn(code: 'S-3')])],
      );
      await notifier().loadMore();

      expect(state().days, hasLength(2));
      expect(state().days.first.date, DateTime.parse('2026-08-21'));
      expect(state().days.last.date, DateTime.parse('2026-08-20'));
      expect(state().hasReachedEnd, isTrue);
    });

    test('it stops asking once every row is loaded', () async {
      repository.nextPage = TransactionPage(
        page: 1,
        limit: 20,
        total: 1,
        days: [day('2026-08-21', subtotal: '10.00', wholeDayCount: 1, rows: [txn(code: 'S-1')])],
      );
      await notifier().loadInitial();

      await notifier().loadMore();

      expect(state().hasReachedEnd, isTrue);
      expect(state().days.single.transactions, hasLength(1));
    });
  });

  group('failure', () {
    test('a first-page failure shows the error screen', () async {
      repository.failWith = const NetworkException();

      await notifier().loadInitial();

      expect(state().status, StateLifeCycle.error);
      expect(state().showFullScreenError, isTrue);
    });

    test('a later-page failure leaves the loaded rows in place', () async {
      repository.nextPage = TransactionPage(
        page: 1,
        limit: 1,
        total: 5,
        days: [day('2026-08-21', subtotal: '10.00', wholeDayCount: 5, rows: [txn(code: 'S-1')])],
      );
      await notifier().loadInitial();

      repository.failWith = const NetworkException();
      await notifier().loadMore();

      expect(state().days.single.transactions, hasLength(1));
      expect(state().showFullScreenError, isFalse);
      expect(state().nextPageFailed, isTrue);
    });
  });

  group('filters', () {
    test('a type filter reloads from the first page', () async {
      repository.nextPage = TransactionPage(
        page: 1,
        limit: 20,
        total: 1,
        days: [day('2026-08-21', subtotal: '10.00', wholeDayCount: 1, rows: [txn(code: 'W-1')])],
      );

      await notifier().setType(TransactionType.writeOff);

      expect(state().filter.type, TransactionType.writeOff);
      expect(state().page, 1);
    });

    test('a search reloads too, and is remembered', () async {
      repository.nextPage = TransactionPage(page: 1, limit: 20, total: 0, days: const []);

      await notifier().search('Lan');

      expect(state().filter.query, 'Lan');
    });

    test('clearing every filter empties the filter', () async {
      repository.nextPage = TransactionPage(page: 1, limit: 20, total: 0, days: const []);
      await notifier().setType(TransactionType.sale);
      await notifier().search('Lan');

      await notifier().clearFilters();

      expect(state().filter.isEmpty, isTrue);
    });

    test('no results with a filter is distinct from nothing recorded', () async {
      repository.nextPage = TransactionPage(page: 1, limit: 20, total: 0, days: const []);

      await notifier().loadInitial();
      expect(state().isEmpty, isTrue);
      expect(state().hasNoResults, isFalse);

      await notifier().search('nothing matches this');
      final filtered = container.read(ledgerListStateProvider);
      expect(filtered.hasNoResults, isTrue);
      expect(filtered.isEmpty, isFalse);
    });
  });

  group('without an active store', () {
    test('it refuses rather than guessing a shop', () async {
      final bare = ProviderContainer(
        overrides: [
          transactionRepositoryProvider.overrideWithValue(repository),
          activeStoreProvider.overrideWith(() => FixedActiveStore(null)),
        ],
      );
      addTearDown(bare.dispose);
      bare.listen(ledgerListStateProvider, (_, _) {}, fireImmediately: true);

      await bare.read(ledgerListStateProvider.notifier).loadInitial();

      expect(bare.read(ledgerListStateProvider).status, StateLifeCycle.error);
    });
  });
}
