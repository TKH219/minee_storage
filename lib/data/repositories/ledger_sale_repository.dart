import 'package:decimal/decimal.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/domain/repositories/transaction_repository.dart';
import 'package:mine_storage/domain/services/fefo_allocator.dart';

/// The sale flow, served by the ledger.
///
/// [SaleRepository] is the seam the drawn S19–S24 screens were built against.
/// This is the implementation that makes them real: a confirmed sale becomes a
/// `sale` transaction, and its stock moves through the one write path the
/// ledger owns rather than through a deduction with no reason attached.
class LedgerSaleRepository implements SaleRepository {
  const LedgerSaleRepository(this._ledger, this._products);

  final TransactionRepository _ledger;
  final ProductRepository _products;

  /// Resolved on the device so the seller sees the split before committing.
  /// The server re-resolves at write time against stock as it stands then —
  /// this is a preview, never a reservation.
  @override
  Future<List<SaleAllocation>> previewAllocation({
    required String productId,
    required String storeId,
    required Decimal quantity,
  }) async {
    final product = await _products.getProduct(productId, storeId: storeId);
    final byId = {for (final batch in product.batches) batch.id: batch};
    return FefoAllocator.allocate(quantity: quantity, batches: product.batches)
        .map((allocation) {
          final batch = byId[allocation.batchId]!;
          return SaleAllocation(
            batchId: batch.id,
            batchCode: batch.batchCode,
            quantity: allocation.quantity,
            unitCost: batch.unitPrice,
            expiryDate: batch.expiryDate,
            remainingAfter: batch.remainingQuantity - allocation.quantity,
          );
        })
        .toList();
  }

  @override
  Future<Sale> confirm(SaleDraft draft, {required String storeId}) async {
    if (draft.isEmpty) {
      throw const BadRequestException(message: 'A sale needs at least one line.');
    }

    // One draft line per resolved lot: the split the seller approved is what
    // gets written, rather than a total the server would re-split its own way.
    final transaction = await _ledger.create(
      TransactionDraft(
        storeId: storeId,
        type: TransactionType.sale,
        paymentMethod: draft.paymentMethod,
        fees: draft.fees,
        lines: [
          for (final line in draft.lines)
            for (final allocation in line.allocations)
              TransactionLineDraft(
                productId: line.productId,
                batchId: allocation.batchId,
                quantity: allocation.quantity,
                unitPrice: line.unitSellPrice,
              ),
        ],
      ),
    );

    return _toSale(transaction);
  }

  @override
  Future<List<Sale>> salesFor({required String storeId}) async {
    final page = await _ledger.list(
      storeId: storeId,
      type: TransactionType.sale,
      limit: 100,
    );
    return [
      for (final day in page.days)
        for (final transaction in day.transactions) _toSale(transaction),
    ];
  }

  @override
  Future<List<String>> recentlySoldProductIds({
    required String storeId,
    int limit = 5,
  }) async {
    final page = await _ledger.list(
      storeId: storeId,
      type: TransactionType.sale,
      limit: 50,
    );
    final ids = <String>{};
    for (final day in page.days) {
      for (final transaction in day.transactions) {
        for (final line in transaction.lines) {
          if (ids.length >= limit) return ids.toList();
          ids.add(line.productId);
        }
      }
    }
    return ids.toList();
  }

  @override
  Future<SalesDashboardSummary> dashboardSummary({
    required String storeId,
    required DateTime today,
  }) async {
    final sales = await salesFor(storeId: storeId);
    final start = DateTime(today.year, today.month, today.day);

    List<Sale> on(DateTime day) =>
        sales.where((sale) => _dayOf(sale.paidAt) == day).toList();

    Decimal sum(Iterable<Decimal> values) =>
        values.fold(Decimal.zero, (total, value) => total + value);

    Decimal revenueOf(List<Sale> group) =>
        sum(group.map((sale) => sale.totals.netRevenue));
    Decimal profitOf(List<Sale> group) =>
        sum(group.map((sale) => sale.totals.netProfit));
    Decimal basketOf(List<Sale> group) => group.isEmpty
        ? Decimal.zero
        : (sum(group.map((sale) => sale.totals.buyerTotal)) /
                  Decimal.fromInt(group.length))
              .toDecimal(scaleOnInfinitePrecision: 6)
              .round(scale: 2);

    final todaySales = on(start);
    final yesterdaySales = on(start.subtract(const Duration(days: 1)));
    final series = [
      for (var back = 6; back >= 0; back--)
        revenueOf(on(start.subtract(Duration(days: back)))),
    ];

    return SalesDashboardSummary(
      revenue: revenueOf(todaySales),
      netProfit: profitOf(todaySales),
      salesCount: todaySales.length,
      avgBasket: basketOf(todaySales),
      revenueDelta: KpiDelta.between(
        revenueOf(todaySales),
        revenueOf(yesterdaySales),
      ),
      netProfitDelta: KpiDelta.between(
        profitOf(todaySales),
        profitOf(yesterdaySales),
      ),
      salesCountDelta: KpiDelta.between(
        Decimal.fromInt(todaySales.length),
        Decimal.fromInt(yesterdaySales.length),
      ),
      avgBasketDelta: KpiDelta.between(
        basketOf(todaySales),
        basketOf(yesterdaySales),
      ),
      lastSevenDaysRevenue: sum(series),
      lastSevenDaysSeries: series,
    );
  }

  static DateTime _dayOf(DateTime moment) =>
      DateTime(moment.year, moment.month, moment.day);

  /// A transaction, read back as the sale the drawn screens expect.
  ///
  /// The ledger stores one line per lot; a sale shows one line per product with
  /// the lots underneath it, so the lines are regrouped on the way out.
  static Sale _toSale(Transaction transaction) {
    final byProduct = <String, List<TransactionLine>>{};
    for (final line in transaction.lines) {
      byProduct.putIfAbsent(line.productId, () => []).add(line);
    }

    return Sale(
      id: transaction.id,
      code: transaction.code,
      storeId: transaction.storeId,
      paidAt: transaction.occurredAt,
      paymentMethod: transaction.paymentMethod ?? PaymentMethod.cash,
      deductedLotCount: transaction.lotCount,
      totals: SaleTotals(
        itemsSubtotal: transaction.money.itemsSubtotal,
        cogs: transaction.money.cogs,
        discountTotal: transaction.money.discountTotal,
        buyerChargeTotal: transaction.money.buyerChargeTotal,
        passThroughTotal: transaction.money.passThroughTotal,
        sellerCostTotal: transaction.money.sellerCostTotal,
        buyerTotal: transaction.money.buyerTotal,
        netRevenue: transaction.money.netRevenue,
        netProfit: transaction.money.netProfit,
        netMargin: transaction.money.netMargin,
        fees: transaction.money.fees,
      ),
      lines: [
        for (final entry in byProduct.entries)
          SaleLine(
            productId: entry.key,
            productName: entry.value.first.productName,
            quantity: entry.value.fold(
              Decimal.zero,
              (sum, line) => sum + line.displayQuantity,
            ),
            unitSellPrice: entry.value.first.unitPrice,
            allocations: [
              for (final line in entry.value)
                SaleAllocation(
                  batchId: line.batchId,
                  batchCode: line.batchCode,
                  quantity: line.displayQuantity,
                  unitCost: line.unitCostSnapshot,
                  expiryDate: line.expiryDate,
                ),
            ],
          ),
      ],
    );
  }
}
