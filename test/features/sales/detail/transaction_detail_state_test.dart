import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/detail/states/transaction_detail_state.dart';
import 'package:mine_storage/providers.dart';

import '../../../support/fake_transaction_repository.dart';
import '../../../support/transaction_fixtures.dart';

void main() {
  late FakeTransactionRepository repository;
  late ProviderContainer container;

  ProviderContainer build() => ProviderContainer(
    overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
  );

  setUp(() {
    repository = FakeTransactionRepository();
    container = build();
    addTearDown(container.dispose);
    container.listen(transactionDetailStateProvider, (_, _) {}, fireImmediately: true);
  });

  TransactionDetailStateNotifier notifier() =>
      container.read(transactionDetailStateProvider.notifier);
  TransactionDetailState state() => container.read(transactionDetailStateProvider);

  group('what the screen may show', () {
    test('a sale carries the full money breakdown and its lot split', () async {
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

      await notifier().load('txn-1');

      expect(state().showsProfit, isTrue);
      expect(state().showsMoney, isTrue);
      expect(state().lotCount, 2);
      expect(state().transaction!.netQuantityDelta, Decimal.parse('-6.000'));
    });

    test('a receive shows money but never a profit row', () async {
      repository.nextById = ledgerTransaction(
        code: 'R-202608-0018',
        type: TransactionType.receive,
        counterparty: 'Dairyland',
      );

      await notifier().load('txn-1');

      expect(state().showsMoney, isTrue);
      expect(state().showsProfit, isFalse);
    });

    test('a write-off shows the loss and no money breakdown at all', () async {
      repository.nextById = ledgerTransaction(
        code: 'W-202608-0007',
        type: TransactionType.writeOff,
        reason: WriteOffReason.expired,
        paymentMethod: null,
        money: ledgerMoney(
          itemsSubtotal: '0.00',
          buyerTotal: '0.00',
          netRevenue: '0.00',
          cogs: '7.20',
          grossProfit: '0.00',
          netProfit: '0.00',
          netMargin: '0.00',
        ),
        lines: [ledgerLine(quantityDelta: '-3.000', lineCost: '7.20', unitCostSnapshot: '2.40')],
      );

      await notifier().load('txn-1');

      expect(state().showsMoney, isFalse);
      expect(state().showsProfit, isFalse);
      expect(state().valueLeavingStock, Decimal.parse('7.20'));
    });

    test('a stock count carries its signed delta and no money at all', () async {
      repository.nextById = ledgerTransaction(
        code: 'A-202608-0003',
        type: TransactionType.adjust,
        paymentMethod: null,
        reasonNote: 'Two cartons crushed',
        money: ledgerMoney(
          itemsSubtotal: '0.00',
          buyerTotal: '0.00',
          netRevenue: '0.00',
          cogs: '0.00',
          grossProfit: '0.00',
          netProfit: '0.00',
          netMargin: '0.00',
        ),
        lines: [ledgerLine(quantityDelta: '-2.000', lineCost: '0.00')],
      );

      await notifier().load('txn-1');

      expect(state().showsMoney, isFalse);
      expect(state().transaction!.netQuantityDelta, Decimal.parse('-2.000'));
    });
  });

  test('a lot re-costed since the sale is flagged, not corrected', () async {
    repository.nextById = ledgerTransaction(
      lines: [ledgerLine(unitCostSnapshot: '1.10', batchUnitCost: '1.30')],
    );

    await notifier().load('txn-1');

    expect(state().movedCostLines.single.unitCostSnapshot, Decimal.parse('1.10'));
    expect(state().movedCostLines.single.batchUnitCost, Decimal.parse('1.30'));
  });

  test('an amended transaction reports when it was edited', () async {
    repository.nextById = ledgerTransaction(amendedAt: DateTime(2026, 8, 26, 14, 2));

    await notifier().load('txn-1');

    expect(state().transaction!.isAmended, isTrue);
    expect(state().transaction!.amendedAt, DateTime(2026, 8, 26, 14, 2));
  });

  group('deleting', () {
    test('the confirmation names what returns to each lot', () async {
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
      await notifier().load('txn-1');

      final returns = state().stockReturns;

      expect(returns.map((r) => r.batchCode), ['L-2608-A', 'L-2608-B']);
      expect(returns.map((r) => r.quantity), [
        Decimal.parse('2.000'),
        Decimal.parse('4.000'),
      ]);
    });

    test('a delete carries the stamp the transaction was read with', () async {
      repository.nextById = ledgerTransaction(updatedTime: DateTime(2026, 8, 26, 9, 12));
      await notifier().load('txn-1');

      await notifier().delete();

      expect(repository.removed, ['txn-1']);
      expect(repository.removedAt, [DateTime(2026, 8, 26, 9, 12)]);
      expect(state().didDelete, isTrue);
    });

    test('a refused reversal names the lot and changes nothing', () async {
      repository.nextById = ledgerTransaction();
      await notifier().load('txn-1');
      repository.failWith = ReversalBlockedException(
        batchCode: 'L-2608-A',
        remaining: Decimal.zero,
        shortfall: Decimal.parse('2.000'),
      );

      await notifier().delete();

      expect(state().didDelete, isFalse);
      expect(state().reversalBlocked!.batchCode, 'L-2608-A');
      expect(state().reversalBlocked!.shortfall, Decimal.parse('2.000'));
      expect(state().transaction, isNotNull);
    });
  });

  test('a load failure leaves the screen with a message and no transaction', () async {
    repository.failWith = const ServerException(message: 'down');

    await notifier().load('txn-1');

    expect(state().isError, isTrue);
    expect(state().transaction, isNull);
  });
}
