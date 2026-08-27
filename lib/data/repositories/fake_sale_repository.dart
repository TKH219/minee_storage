import 'package:decimal/decimal.dart';
import 'package:flutter/foundation.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/repositories/sale_repository.dart';
import 'package:mine_storage/domain/services/fefo_allocator.dart';

/// In-memory stand-in for the sales tables, alongside [FakeProductRepository].
///
/// It draws stock through that stand-in rather than holding its own copy, so a
/// sale and the product list can never disagree about what is left. It is bound
/// to the concrete fake on purpose: moving stock is the ledger's job, so no
/// such method exists on [ProductRepository] to reach through.
class FakeSaleRepository implements SaleRepository {
  FakeSaleRepository(
    this._products, {
    this.latency = const Duration(milliseconds: 250),
    int startingCode = 1042,
  }) : _nextCode = startingCode;

  final FakeProductRepository _products;

  /// Fakes network delay so loading states are visible on device. Widget tests
  /// pass [Duration.zero].
  final Duration latency;

  final List<Sale> _sales = [];
  int _nextCode;

  @override
  Future<List<SaleAllocation>> previewAllocation({
    required String productId,
    required String storeId,
    required Decimal quantity,
  }) async {
    await Future<void>.delayed(latency);
    final product = await _products.getProduct(productId, storeId: storeId);
    return _resolve(product, quantity);
  }

  List<SaleAllocation> _resolve(ProductEntity product, Decimal quantity) {
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
    await Future<void>.delayed(latency);
    if (draft.isEmpty) {
      throw const BadRequestException(message: 'A sale needs at least one line.');
    }

    // §5.4.2 in two halves: every lot is revalidated before a single one is
    // touched, so a shortfall on the last line cannot leave the first deducted.
    final current = <String, ProductEntity>{};
    for (final line in draft.lines) {
      current[line.productId] ??= await _products.getProduct(
        line.productId,
        storeId: storeId,
      );
      final batches = {
        for (final batch in current[line.productId]!.batches) batch.id: batch,
      };
      for (final allocation in line.allocations) {
        final batch = batches[allocation.batchId];
        final available = batch?.remainingQuantity ?? Decimal.zero;
        if (available < allocation.quantity) {
          throw InsufficientStockException(
            requested: allocation.quantity,
            available: available,
          );
        }
      }
    }

    for (final line in draft.lines) {
      await _products.applyLedgerDeltas(
        line.productId,
        [
          for (final allocation in line.allocations)
            BatchAllocation(
              batchId: allocation.batchId,
              quantity: allocation.quantity,
            ),
        ],
        storeId: storeId,
      );
    }

    final number = _nextCode++;
    final sale = Sale(
      // The id travels in a URL, so it carries no '#' — that is the display
      // code's own decoration and would start a fragment.
      id: 'sale-$number',
      code: '#$number',
      storeId: storeId,
      paidAt: DateTime.now(),
      paymentMethod: draft.paymentMethod,
      totals: draft.totals,
      deductedLotCount: draft.lotCount,
      lines: [
        for (final line in draft.lines)
          SaleLine(
            productId: line.productId,
            productName: line.productName,
            quantity: line.quantity,
            unitSellPrice: line.unitSellPrice,
            allocations: line.allocations,
          ),
      ],
    );
    _sales.add(sale);
    return sale;
  }

  /// Appends a paid sale without touching stock, so a test can seed the
  /// figures a dashboard reads without seeding twenty lots to draw them from.
  @visibleForTesting
  Sale recordAt(SaleDraft draft, {required String storeId, required DateTime at}) {
    final number = _nextCode++;
    final sale = Sale(
      // The id travels in a URL, so it carries no '#' — that is the display
      // code's own decoration and would start a fragment.
      id: 'sale-$number',
      code: '#$number',
      storeId: storeId,
      paidAt: at,
      paymentMethod: draft.paymentMethod,
      totals: draft.totals,
      deductedLotCount: draft.lotCount,
      lines: [
        for (final line in draft.lines)
          SaleLine(
            productId: line.productId,
            productName: line.productName,
            quantity: line.quantity,
            unitSellPrice: line.unitSellPrice,
            allocations: line.allocations,
          ),
      ],
    );
    _sales.add(sale);
    return sale;
  }

  @override
  Future<List<Sale>> salesFor({required String storeId}) async {
    await Future<void>.delayed(latency);
    return _recorded(storeId);
  }

  List<Sale> _recorded(String storeId) =>
      _sales.where((sale) => sale.storeId == storeId).toList().reversed.toList();

  @override
  Future<SalesDashboardSummary> dashboardSummary({
    required String storeId,
    required DateTime today,
  }) async {
    await Future<void>.delayed(latency);
    final recorded = _recorded(storeId);
    final start = DateTime(today.year, today.month, today.day);

    List<Sale> on(DateTime day) => recorded
        .where((sale) => _dayOf(sale.paidAt) == day)
        .toList();

    Decimal sum(Iterable<Decimal> values) =>
        values.fold(Decimal.zero, (total, value) => total + value);

    final todaySales = on(start);
    final yesterdaySales = on(start.subtract(const Duration(days: 1)));

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

  @override
  Future<List<String>> recentlySoldProductIds({
    required String storeId,
    int limit = 5,
  }) async {
    await Future<void>.delayed(latency);
    final ids = <String>{};
    for (final sale in _recorded(storeId)) {
      for (final line in sale.lines) {
        if (ids.length >= limit) return ids.toList();
        ids.add(line.productId);
      }
    }
    return ids.toList();
  }
}
