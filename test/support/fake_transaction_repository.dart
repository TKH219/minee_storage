import 'package:decimal/decimal.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';

/// An in-memory ledger. Records what it was asked to write so a test can assert
/// that a draft became the transaction it should have, and can be told to
/// refuse so the caller's error path is exercised.
class FakeTransactionRepository implements TransactionRepository {
  FakeTransactionRepository({this.latency = Duration.zero});

  final Duration latency;

  final List<TransactionDraft> created = [];
  final List<TransactionDraft> amended = [];
  final List<DateTime> amendedAt = [];
  final List<String> removed = [];
  final List<DateTime> removedAt = [];
  final List<TransactionDraft> previewed = [];

  AppException? failWith;
  int amendAttempts = 0;

  /// What the next write returns. Defaults to a sale echoing the draft.
  Transaction Function(TransactionDraft draft)? build;

  /// What the next preview resolves to.
  List<ResolvedLine> previewResolvesTo = const [];

  TransactionPage nextPage = TransactionPage.empty;
  Transaction? nextById;

  Future<void> _wait() async {
    await Future<void>.delayed(latency);
    final failure = failWith;
    if (failure != null) throw failure;
  }

  Transaction _echo(TransactionDraft draft, {int index = 1}) {
    var order = 0;
    final lines = [
      for (final line in draft.lines)
        TransactionLine(
          id: 'line-${order + 1}',
          transactionId: 'txn-$index',
          productId: line.productId,
          batchId: line.batchId ?? 'batch-${order + 1}',
          batchCode: '#B-000${order + 1}',
          productName: 'Product ${line.productId}',
          unit: ProductUnit.piece,
          quantityDelta: draft.type == TransactionType.receive
              ? line.quantity
              : -line.quantity,
          unitPrice: line.unitPrice ?? Decimal.zero,
          unitCostSnapshot: Decimal.parse('1.00'),
          lineGross: line.quantity * (line.unitPrice ?? Decimal.zero),
          lineCost: line.quantity,
          sortOrder: order++,
        ),
    ];

    final subtotal = lines.fold(
      Decimal.zero,
      (sum, line) => sum + line.lineGross,
    );
    final cogs = lines
        .where((line) => line.isOutward)
        .fold(Decimal.zero, (sum, line) => sum + line.lineCost);

    return Transaction(
      id: 'txn-$index',
      storeId: draft.storeId,
      type: draft.type,
      code: '${_prefix(draft.type)}-202608-${index.toString().padLeft(4, '0')}',
      occurredAt: draft.occurredAt ?? DateTime(2026, 8, 21, 10),
      paymentMethod: draft.paymentMethod,
      reason: draft.reason,
      reasonNote: draft.reasonNote,
      counterparty: draft.counterparty,
      lines: lines,
      money: TransactionMoney.compute(
        type: draft.type,
        itemsSubtotal: subtotal,
        cogs: cogs,
        fees: draft.fees,
        decimals: 2,
      ),
      createdTime: DateTime(2026, 8, 21, 10),
      updatedTime: DateTime(2026, 8, 21, 10),
    );
  }

  static String _prefix(TransactionType type) => switch (type) {
    TransactionType.sale => 'S',
    TransactionType.receive => 'R',
    TransactionType.writeOff => 'W',
    TransactionType.adjust => 'A',
  };

  @override
  Future<TransactionPage> list({
    required String storeId,
    TransactionType? type,
    DateTime? from,
    DateTime? to,
    String? productId,
    PaymentMethod? paymentMethod,
    String? query,
    int page = 1,
    int limit = 20,
  }) async {
    await _wait();
    return nextPage;
  }

  @override
  Future<Transaction> byId(String id) async {
    await _wait();
    return nextById ?? _echo(created.last);
  }

  @override
  Future<Transaction> create(TransactionDraft draft) async {
    await _wait();
    created.add(draft);
    return (build ?? (d) => _echo(d, index: created.length))(draft);
  }

  @override
  Future<Transaction> amend(
    String id,
    TransactionDraft draft, {
    required DateTime expectedUpdatedAt,
  }) async {
    amendAttempts++;
    await _wait();
    amended.add(draft);
    amendedAt.add(expectedUpdatedAt);
    return (build ?? (d) => _echo(d))(draft);
  }

  @override
  Future<Transaction> remove(
    String id, {
    required DateTime expectedUpdatedAt,
  }) async {
    await _wait();
    removed.add(id);
    removedAt.add(expectedUpdatedAt);
    return _echo(created.isEmpty ? _emptyDraft : created.last);
  }

  @override
  Future<TransactionPreview> preview(TransactionDraft draft) async {
    await _wait();
    previewed.add(draft);
    final lines = previewResolvesTo.isNotEmpty
        ? previewResolvesTo
        : [
            for (final line in draft.lines)
              ResolvedLine(
                productId: line.productId,
                batchId: line.batchId ?? 'batch-1',
                batchCode: '#B-0001',
                productName: 'Product ${line.productId}',
                quantityDelta: -line.quantity,
                unitPrice: line.unitPrice ?? Decimal.zero,
                unitCostSnapshot: Decimal.parse('1.00'),
                lineGross: line.quantity * (line.unitPrice ?? Decimal.zero),
                lineCost: line.quantity,
              ),
          ];
    return TransactionPreview(
      storeId: draft.storeId,
      type: draft.type,
      currencyMinorUnits: 2,
      money: TransactionMoney.compute(
        type: draft.type,
        itemsSubtotal: lines.fold(Decimal.zero, (sum, l) => sum + l.lineGross),
        cogs: lines.fold(Decimal.zero, (sum, l) => sum + l.lineCost),
        fees: draft.fees,
        decimals: 2,
      ),
      lines: lines,
    );
  }

  static const TransactionDraft _emptyDraft = TransactionDraft(
    storeId: 'store-1',
    type: TransactionType.sale,
    lines: [],
  );
}
