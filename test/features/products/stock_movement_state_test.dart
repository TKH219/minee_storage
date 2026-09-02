import 'package:decimal/decimal.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/detail/states/receive_state.dart';
import 'package:mine_storage/features/products/detail/states/stock_count_state.dart';
import 'package:mine_storage/features/products/detail/states/write_off_state.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/providers.dart';

import '../../support/active_store_override.dart';
import '../../support/fake_transaction_repository.dart';

void main() {
  Decimal d(String value) => Decimal.parse(value);

  ProductBatchEntity lot({
    required String id,
    required String code,
    String received = '20.000',
    String remaining = '15.000',
    String unitPrice = '2.40',
    DateTime? expiry,
  }) => ProductBatchEntity(
    id: id,
    productId: 'product-1',
    storeId: 'store-1',
    batchCode: code,
    purchasedAt: DateTime(2026, 8, 1),
    unitPrice: d(unitPrice),
    expiryDate: expiry,
    initialQuantity: d(received),
    remainingQuantity: d(remaining),
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
  );

  ProductEntity product({List<ProductBatchEntity>? batches}) => ProductEntity(
    id: 'product-1',
    name: 'Greek Yoghurt 500g',
    unit: ProductUnit.piece,
    createdAt: DateTime(2026, 8, 1),
    updatedAt: DateTime(2026, 8, 1),
    batches: batches ?? [lot(id: 'batch-1', code: 'L-2508-C', remaining: '3.000')],
  );

  late FakeTransactionRepository repository;
  late ProviderContainer container;

  setUp(() {
    repository = FakeTransactionRepository();
    container = ProviderContainer(
      overrides: [
        transactionRepositoryProvider.overrideWithValue(repository),
        activeStoreProvider.overrideWith(() => FixedActiveStore('store-1')),
      ],
    );
    addTearDown(container.dispose);
    container.listen(writeOffStateProvider, (_, _) {}, fireImmediately: true);
    container.listen(stockCountStateProvider, (_, _) {}, fireImmediately: true);
    container.listen(receiveStateProvider, (_, _) {}, fireImmediately: true);
  });

  group('writing stock off', () {
    WriteOffStateNotifier notifier() => container.read(writeOffStateProvider.notifier);
    WriteOffState state() => container.read(writeOffStateProvider);

    test('opens on the lot that expires first', () {
      notifier().open(
        product(
          batches: [
            lot(id: 'batch-late', code: 'L-B', expiry: DateTime(2026, 12, 1)),
            lot(id: 'batch-soon', code: 'L-A', expiry: DateTime(2026, 9, 1)),
          ],
        ),
      );

      expect(state().batch!.id, 'batch-soon');
    });

    test('a quantity cannot exceed what the lot holds', () {
      notifier().open(product());

      notifier().updateQuantity('4');

      expect(state().exceedsLot, isTrue);
      expect(state().canCommit, isFalse);
    });

    test('a fraction against a counted unit is refused at input', () {
      notifier().open(product());

      notifier().updateQuantity('1.5');

      expect(state().fractionRefused, isTrue);
      expect(state().canCommit, isFalse);
    });

    test('the value leaving stock is the lot cost times the quantity', () {
      notifier().open(product());

      notifier().updateQuantity('3');

      expect(state().valueLeaving, d('7.20'));
      expect(state().canCommit, isTrue);
    });

    test('a commit writes one write-off line against the chosen lot', () async {
      notifier().open(product());
      notifier().updateQuantity('3');
      notifier().selectReason(WriteOffReason.damaged);
      notifier().updateNote('Found swollen');

      await notifier().commit();

      final draft = repository.created.single;
      expect(draft.type, TransactionType.writeOff);
      expect(draft.reason, WriteOffReason.damaged);
      expect(draft.reasonNote, 'Found swollen');
      expect(draft.lines.single.batchId, 'batch-1');
      expect(draft.lines.single.quantity, d('3'));
      expect(state().didCommit, isTrue);
    });

    test('nothing leaves the device when the quantity is short', () async {
      notifier().open(product());
      notifier().updateQuantity('9');

      await notifier().commit();

      expect(repository.created, isEmpty);
    });
  });

  group('counting a lot', () {
    StockCountStateNotifier notifier() =>
        container.read(stockCountStateProvider.notifier);
    StockCountState state() => container.read(stockCountStateProvider);

    test('a count of 13 against a lot of 20 with 5 sold shows a -2 difference', () {
      notifier().open(product(batches: [lot(id: 'batch-1', code: 'L-A')]));

      notifier().updateCounted('13');

      expect(state().difference, d('-2.000'));
    });

    test('the count is sent as counted, and the server derives the delta', () async {
      notifier().open(product(batches: [lot(id: 'batch-1', code: 'L-A')]));
      notifier().updateCounted('13');
      notifier().updateReason('recount');

      await notifier().commit();

      final draft = repository.created.single;
      expect(draft.type, TransactionType.adjust);
      expect(draft.reasonNote, 'recount');
      expect(draft.lines.single.batchId, 'batch-1');
      expect(draft.lines.single.quantity, d('13'));
      expect(state().didCommit, isTrue);
    });

    test('a count carries no money at all', () async {
      notifier().open(product(batches: [lot(id: 'batch-1', code: 'L-A')]));
      notifier().updateCounted('13');
      notifier().updateReason('recount');

      await notifier().commit();

      final written = repository.created.single;
      expect(written.fees, isEmpty);
      expect(written.paymentMethod, isNull);
      expect(written.lines.single.unitPrice, isNull);
    });

    test('a reason is required before the count can be applied', () {
      notifier().open(product(batches: [lot(id: 'batch-1', code: 'L-A')]));

      notifier().updateCounted('13');

      expect(state().canCommit, isFalse);

      notifier().updateReason('recount');

      expect(state().canCommit, isTrue);
    });

    test('a count matching what the lot holds writes nothing', () async {
      notifier().open(product(batches: [lot(id: 'batch-1', code: 'L-A')]));
      notifier().updateCounted('15');
      notifier().updateReason('checked');

      expect(state().isUnchanged, isTrue);
      expect(state().canCommit, isFalse);

      await notifier().commit();

      expect(repository.created, isEmpty);
    });
  });

  group('receiving a delivery', () {
    ReceiveStateNotifier notifier() => container.read(receiveStateProvider.notifier);
    ReceiveState state() => container.read(receiveStateProvider);

    test('a receive creates the lot through the ledger, not beside it', () async {
      notifier().open(product());
      notifier().updateQuantity('40');
      notifier().updateUnitCost('1.20');
      notifier().updateBatchCode('L-2608-D');
      notifier().updateSupplier('Dairyland');
      notifier().updateStorageLocation('Cold room A');
      notifier().updateExpiry(DateTime(2026, 9, 30));
      notifier().selectPaymentMethod(PaymentMethod.bankTransfer);

      await notifier().commit();

      final draft = repository.created.single;
      expect(draft.type, TransactionType.receive);
      expect(draft.counterparty, 'Dairyland');
      expect(draft.paymentMethod, PaymentMethod.bankTransfer);
      final line = draft.lines.single;
      expect(line.batchId, isNull);
      expect(line.quantity, d('40'));
      expect(line.unitPrice, d('1.20'));
      expect(line.batch!.batchCode, 'L-2608-D');
      expect(line.batch!.expiryDate, DateTime(2026, 9, 30));
      expect(line.batch!.storageLocation, 'Cold room A');
      expect(state().didCommit, isTrue);
    });

    test('fees that fold into cost travel with the delivery', () async {
      notifier().open(product());
      notifier().updateQuantity('40');
      notifier().updateUnitCost('1.20');
      notifier().updateFees([
        Fee(
          id: 'fee-1',
          name: 'Freight',
          kind: FeeKind.fixed,
          value: d('6.00'),
          direction: FeeDirection.buyerCharge,
        ),
      ]);

      await notifier().commit();

      expect(repository.created.single.fees.single.name, 'Freight');
      expect(state().goodsTotal, d('48.00'));
    });

    test('a fraction against a counted unit is refused at input', () {
      notifier().open(product());
      notifier().updateUnitCost('1.20');

      notifier().updateQuantity('1.5');

      expect(state().fractionRefused, isTrue);
      expect(state().canCommit, isFalse);
    });
  });
}
