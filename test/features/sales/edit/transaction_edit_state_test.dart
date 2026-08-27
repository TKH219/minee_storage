import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/edit/states/transaction_edit_state.dart';
import 'package:mine_storage/providers.dart';

import '../../../support/fake_transaction_repository.dart';
import '../../../support/transaction_fixtures.dart';

void main() {
  late FakeTransactionRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeTransactionRepository();
    container = ProviderContainer(
      overrides: [transactionRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.listen(transactionEditStateProvider, (_, _) {}, fireImmediately: true);
  });

  TransactionEditStateNotifier notifier() =>
      container.read(transactionEditStateProvider.notifier);
  TransactionEditState state() => container.read(transactionEditStateProvider);

  ResolvedLine resolved(String code, String quantity, {String cost = '1.25'}) =>
      ResolvedLine(
        productId: 'product-1',
        batchId: 'batch-$code',
        batchCode: code,
        productName: 'Whole Milk 1L',
        quantityDelta: Decimal.parse('-$quantity'),
        unitPrice: Decimal.parse('1.80'),
        unitCostSnapshot: Decimal.parse(cost),
        lineGross: Decimal.parse(quantity) * Decimal.parse('1.80'),
        lineCost: Decimal.parse(quantity) * Decimal.parse(cost),
      );

  Transaction sale() => ledgerTransaction(
    lines: [
      ledgerLine(
        batchId: 'batch-L-2608-A',
        batchCode: 'L-2608-A',
        quantityDelta: '-2.000',
        unitCostSnapshot: '1.10',
        lineCost: '2.20',
      ),
      ledgerLine(
        id: 'line-2',
        batchId: 'batch-L-2608-B',
        batchCode: 'L-2608-B',
        quantityDelta: '-4.000',
        unitCostSnapshot: '1.25',
        lineCost: '5.00',
      ),
    ],
    money: ledgerMoney(cogs: '7.20'),
  );

  test('opening carries the quantity each product currently holds', () async {
    repository.nextById = sale();

    await notifier().load('txn-1');

    expect(state().transaction, isNotNull);
    expect(state().quantityFor('product-1'), Decimal.parse('6.000'));
    expect(state().originalLots.map((lot) => lot.batchCode), [
      'L-2608-A',
      'L-2608-B',
    ]);
  });

  test('a re-resolved lot set is named before commit, not after', () async {
    repository.nextById = sale();
    await notifier().load('txn-1');
    repository.previewResolvesTo = [
      resolved('L-2608-B', '8.000'),
      resolved('L-2609-A', '1.000', cost: '1.40'),
    ];

    notifier().setQuantity('product-1', '9');
    await notifier().preview();

    expect(state().lotSetChanged, isTrue);
    expect(state().newLots.map((lot) => lot.batchCode), ['L-2608-B', 'L-2609-A']);
    expect(repository.amended, isEmpty);
  });

  test('the cost this edit adds is stated in figures before saving', () async {
    repository.nextById = sale();
    await notifier().load('txn-1');
    repository.previewResolvesTo = [
      resolved('L-2608-B', '8.000'),
      resolved('L-2609-A', '1.000', cost: '1.40'),
    ];

    notifier().setQuantity('product-1', '9');
    await notifier().preview();

    expect(state().originalCogs, Decimal.parse('7.20'));
    expect(state().previewedCogs, Decimal.parse('11.40'));
    expect(state().cogsDelta, Decimal.parse('4.20'));
  });

  test('saving carries the stamp the transaction was read with', () async {
    repository.nextById = sale();
    await notifier().load('txn-1');
    notifier().setQuantity('product-1', '9');
    await notifier().preview();

    await notifier().commit();

    expect(repository.amended, hasLength(1));
    expect(repository.amendedAt.single, DateTime(2026, 8, 26, 9, 12));
    expect(state().didSave, isTrue);
  });

  test('a stale amend reloads and shows what moved rather than retrying', () async {
    repository.nextById = sale();
    await notifier().load('txn-1');
    notifier().setQuantity('product-1', '9');
    await notifier().preview();
    repository.failWith = const StaleTransactionException();

    await notifier().commit();

    expect(state().isStale, isTrue);
    expect(state().didSave, isFalse);
    expect(repository.amendAttempts, 1);
  });

  test('reloading after a stale write replaces the edits with the server row', () async {
    repository.nextById = sale();
    await notifier().load('txn-1');
    notifier().setQuantity('product-1', '9');
    await notifier().preview();
    repository.failWith = const StaleTransactionException();
    await notifier().commit();

    repository.failWith = null;
    repository.nextById = ledgerTransaction(
      lines: [ledgerLine(quantityDelta: '-5.000')],
      updatedTime: DateTime(2026, 8, 26, 14, 31),
    );
    await notifier().reload();

    expect(state().isStale, isFalse);
    expect(state().quantityFor('product-1'), Decimal.parse('5.000'));
  });

  test('an unchanged transaction cannot be saved', () async {
    repository.nextById = sale();

    await notifier().load('txn-1');

    expect(state().hasChanges, isFalse);
    expect(state().canSave, isFalse);
  });
}
