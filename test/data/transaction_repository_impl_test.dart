import 'package:decimal/decimal.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/error_codes.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/core/network/interceptors/error_interceptor.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/data/repositories/transaction_repository_impl.dart';
import 'package:mine_storage/domain/entities/entities.dart';

import '../support/fake_transaction_api.dart';

void main() {
  TransactionLineModel line({
    String quantityDelta = '-5.000',
    String unitPrice = '7.16',
    String unitCostSnapshot = '5.00',
    String? batchUnitCost,
  }) => TransactionLineModel(
    id: 'l-1',
    transactionId: 't-1',
    productId: 'p-1',
    batchId: 'b-1',
    batchCode: '#B-0007',
    productName: 'Whole Milk 1L',
    unit: 'litre',
    quantityDelta: quantityDelta,
    unitPrice: unitPrice,
    unitCostSnapshot: unitCostSnapshot,
    batchUnitCost: batchUnitCost,
    lineGross: '35.80',
    lineCost: '25.00',
  );

  TransactionModel model({
    String type = 'sale',
    List<TransactionLineModel>? lines,
    List<TransactionFeeModel> fees = const [],
    String? paymentMethod = 'cash',
    String? reason,
    String? amendedAt,
    int revision = 0,
  }) => TransactionModel(
    id: 't-1',
    storeId: 's-1',
    type: type,
    code: 'S-202608-0041',
    occurredAt: '2026-08-21T10:00:00Z',
    itemsSubtotal: '35.80',
    discountTotal: '1.79',
    buyerChargeTotal: '4.72',
    sellerCostTotal: '0.51',
    passThroughTotal: '2.72',
    buyerTotal: '38.73',
    netRevenue: '35.50',
    cogs: '25.00',
    grossProfit: '9.01',
    netProfit: '10.50',
    netMargin: '0.295775',
    lines: lines ?? [line()],
    fees: fees,
    paymentMethod: paymentMethod,
    reason: reason,
    amendedAt: amendedAt,
    revision: revision,
    createdAt: '2026-08-21T10:00:00Z',
    updatedAt: '2026-08-21T10:00:00Z',
  );

  DioException dioError(int status, String code) => DioException(
    requestOptions: RequestOptions(path: '/transactions'),
    type: DioExceptionType.badResponse,
    response: Response<dynamic>(
      requestOptions: RequestOptions(path: '/transactions'),
      statusCode: status,
      data: {'code': code, 'message': 'lot #B-0007 holds 2, short by 3'},
    ),
  );

  /// The repository does not map errors itself — [ErrorInterceptor] does, before
  /// the failure ever reaches it. Running a DioException through the same
  /// mapper is what the app actually does.
  AppException mapped(DioException error) =>
      ErrorInterceptor.mapError(error);

  late FakeTransactionApi api;
  late TransactionRepositoryImpl repository;

  setUp(() {
    api = FakeTransactionApi();
    repository = TransactionRepositoryImpl(transactionApi: api);
  });

  final draft = TransactionDraft(
    storeId: 's-1',
    type: TransactionType.sale,
    paymentMethod: PaymentMethod.cash,
    lines: [
      TransactionLineDraft(
        productId: 'p-1',
        quantity: Decimal.parse('5'),
        unitPrice: Decimal.parse('7.16'),
      ),
    ],
  );

  group('decimals survive the wire', () {
    test('a quantity round-trips at three places without float drift', () async {
      api.transaction = model(lines: [line(quantityDelta: '-1234.567')]);

      final transaction = await repository.byId('t-1');

      expect(transaction.lines.single.quantityDelta, Decimal.parse('-1234.567'));
    });

    test('a large price round-trips at two places without float drift', () async {
      api.transaction = model(lines: [line(unitPrice: '99999999.99')]);

      final transaction = await repository.byId('t-1');

      expect(transaction.lines.single.unitPrice, Decimal.parse('99999999.99'));
    });

    test('every money figure arrives as a Decimal', () async {
      api.transaction = model();

      final money = (await repository.byId('t-1')).money;

      expect(money.itemsSubtotal, Decimal.parse('35.80'));
      expect(money.buyerTotal, Decimal.parse('38.73'));
      expect(money.netRevenue, Decimal.parse('35.50'));
      expect(money.grossProfit, Decimal.parse('9.01'));
      expect(money.netProfit, Decimal.parse('10.50'));
      expect(money.netMargin, Decimal.parse('0.295775'));
    });
  });

  group('the sign of the delta, not the type, gives the direction', () {
    test('a sale line points outward', () async {
      api.transaction = model(lines: [line(quantityDelta: '-5.000')]);

      final resolved = (await repository.byId('t-1')).lines.single;

      expect(resolved.isOutward, isTrue);
      expect(resolved.displayQuantity, Decimal.parse('5.000'));
    });

    test('a receive line points inward', () async {
      api.transaction = model(
        type: 'receive',
        lines: [line(quantityDelta: '20.000')],
      );

      final resolved = (await repository.byId('t-1')).lines.single;

      expect(resolved.isOutward, isFalse);
      expect(resolved.displayQuantity, Decimal.parse('20.000'));
    });

    test('a stock count that finds more points inward on the same type', () async {
      api.transaction = model(
        type: 'adjust',
        paymentMethod: null,
        lines: [line(quantityDelta: '3.000')],
      );

      final transaction = await repository.byId('t-1');

      expect(transaction.type, TransactionType.adjust);
      expect(transaction.lines.single.isOutward, isFalse);
    });

    test('a stock count that finds fewer points outward on that same type', () async {
      api.transaction = model(
        type: 'adjust',
        paymentMethod: null,
        lines: [line(quantityDelta: '-2.000')],
      );

      expect((await repository.byId('t-1')).lines.single.isOutward, isTrue);
    });
  });

  group('a lot re-costed since the line froze its own', () {
    test('is flagged when the two figures disagree', () async {
      api.transaction = model(
        lines: [line(unitCostSnapshot: '5.00', batchUnitCost: '6.50')],
      );

      final transaction = await repository.byId('t-1');

      expect(transaction.lines.single.costHasMoved, isTrue);
      expect(transaction.anyCostHasMoved, isTrue);
    });

    test('is not flagged when they agree', () async {
      api.transaction = model(
        lines: [line(unitCostSnapshot: '5.00', batchUnitCost: '5.00')],
      );

      expect((await repository.byId('t-1')).anyCostHasMoved, isFalse);
    });
  });

  group('the wire shape a write sends', () {
    test('a quantity leaves positive; the server applies the sign', () async {
      api.transaction = model();

      await repository.create(draft);

      final sent = api.lastCreate!.toJson();
      expect(sent['type'], 'sale');
      expect((sent['lines'] as List).single['quantity'], '5');
      expect(sent['expectedUpdatedAt'], isNull, reason: 'a create locks nothing');
    });

    test('a pass-through fee leaves as a buyer charge plus a flag', () async {
      api.transaction = model();

      await repository.create(
        draft.copyWith(
          fees: [
            Fee(
              id: 'v',
              name: 'VAT',
              kind: FeeKind.percent,
              value: Decimal.parse('8'),
              direction: FeeDirection.passThrough,
            ),
          ],
        ),
      );

      final fee = (api.lastCreate!.toJson()['fees'] as List).single;
      expect(fee['direction'], 'buyer_charge');
      expect(fee['isPassThrough'], isTrue);
    });

    test('an amend carries the stamp the entity was read with', () async {
      api.transaction = model();
      final readAt = DateTime.utc(2026, 8, 21, 10);

      await repository.amend('t-1', draft, expectedUpdatedAt: readAt);

      expect(api.lastAmend!.toJson()['expectedUpdatedAt'], '2026-08-21T10:00:00.000Z');
    });

    test('a delete carries it too', () async {
      api.transaction = model();

      await repository.remove(
        't-1',
        expectedUpdatedAt: DateTime.utc(2026, 8, 21, 10),
      );

      expect(api.lastRemove!.toJson()['expectedUpdatedAt'], '2026-08-21T10:00:00.000Z');
    });

    test('a filter travels as query parameters, omitting what was not asked', () async {
      api.page = const TransactionPageModel(page: 1, limit: 20, total: 0);

      await repository.list(
        storeId: 's-1',
        type: TransactionType.writeOff,
        paymentMethod: PaymentMethod.bankTransfer,
        query: 'Lan',
      );

      expect(api.lastFilter!['type'], 'write_off');
      expect(api.lastFilter!['paymentMethod'], 'bank_transfer');
      expect(api.lastFilter!['q'], 'Lan');
      expect(api.lastFilter!.containsKey('productId'), isFalse);
    });
  });

  group('every refusal arrives typed', () {
    test('a reversal below zero', () {
      expect(
        mapped(dioError(409, ServerErrorCodes.reversalBelowZero)),
        isA<ReversalBlockedException>(),
      );
    });

    test('a reversal above what the lot received', () {
      expect(
        mapped(dioError(409, ServerErrorCodes.reversalAboveReceived)),
        isA<ReversalBlockedException>(),
      );
    });

    test('a lot already drawn from', () {
      expect(
        mapped(dioError(409, ServerErrorCodes.batchAlreadyDrawn)),
        isA<ReversalBlockedException>(),
      );
    });

    test('a stale edit', () {
      expect(
        mapped(dioError(409, ServerErrorCodes.staleTransaction)),
        isA<StaleTransactionException>(),
      );
    });

    test('a date before the stock arrived', () {
      expect(
        mapped(dioError(409, ServerErrorCodes.occurredBeforeArrival)),
        isA<OccurredBeforeArrivalException>(),
      );
    });

    test('a fee the movement may not carry', () {
      expect(
        mapped(dioError(400, ServerErrorCodes.feeNotAllowed)),
        isA<FeeNotAllowedException>(),
      );
    });

    test('running short of stock', () {
      expect(
        mapped(dioError(409, ServerErrorCodes.insufficientStock)),
        isA<InsufficientStockException>(),
      );
    });

    test('a refusal keeps the server\'s own wording, which names the figures', () {
      final exception = mapped(dioError(409, ServerErrorCodes.reversalBelowZero));
      expect(exception.message, contains('#B-0007'));
      expect(exception.message, contains('short by 3'));
    });
  });

  group('the day grouping the server computed', () {
    test('carries the whole day\'s subtotal, not the page\'s slice', () async {
      api.page = TransactionPageModel(
        page: 1,
        limit: 4,
        total: 7,
        days: [
          TransactionDayModel(
            date: '2026-08-21',
            subtotal: '77.90',
            transactionCount: 7,
            transactions: [model(), model()],
          ),
        ],
      );

      final result = await repository.list(storeId: 's-1', limit: 4);
      final day = result.days.single;

      expect(day.subtotal, Decimal.parse('77.90'));
      expect(day.transactionCount, 7);
      expect(day.transactions, hasLength(2));
      expect(day.isPartial, isTrue, reason: 'the page carries only part of the day');
      expect(result.hasMore, isTrue);
    });
  });

  group('an amended transaction', () {
    test('says so, and carries the stamp', () async {
      api.transaction = model(amendedAt: '2026-08-22T09:00:00Z', revision: 2);

      final transaction = await repository.byId('t-1');

      expect(transaction.isAmended, isTrue);
      expect(transaction.revision, 2);
      expect(transaction.amendedAt, DateTime.utc(2026, 8, 22, 9));
    });

    test('a fresh one does not', () async {
      api.transaction = model();
      expect((await repository.byId('t-1')).isAmended, isFalse);
    });
  });
}
