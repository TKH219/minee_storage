import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

enum DeltaDirection { up, down, flat }

/// One KPI's movement against the same figure yesterday.
///
/// Named for the sales dashboard specifically: the storage-unit domain carries
/// a dashboard summary of its own that means something else entirely.
class KpiDelta extends Equatable {
  const KpiDelta({required this.direction, required this.percent});

  /// A rise out of nothing has no percentage to quote — the tile reads "new"
  /// rather than dividing by zero.
  factory KpiDelta.between(Decimal today, Decimal yesterday) {
    if (today == yesterday) return flat;
    final rising = today > yesterday;
    if (yesterday == Decimal.zero) {
      return KpiDelta(
        direction: rising ? DeltaDirection.up : DeltaDirection.down,
        percent: Decimal.zero,
      );
    }
    final change =
        (today - yesterday).abs() * Decimal.fromInt(100) / yesterday.abs();
    return KpiDelta(
      direction: rising ? DeltaDirection.up : DeltaDirection.down,
      percent: change.toDecimal(scaleOnInfinitePrecision: 4).round(),
    );
  }

  static final KpiDelta flat = KpiDelta(
    direction: DeltaDirection.flat,
    percent: Decimal.zero,
  );

  final DeltaDirection direction;

  /// The magnitude of the change, never its sign — [direction] carries that.
  final Decimal percent;

  bool get hasPercent =>
      direction != DeltaDirection.flat && percent > Decimal.zero;

  @override
  List<Object?> get props => [direction, percent];
}

class SalesDashboardSummary extends Equatable {
  const SalesDashboardSummary({
    required this.revenue,
    required this.netProfit,
    required this.salesCount,
    required this.avgBasket,
    required this.revenueDelta,
    required this.netProfitDelta,
    required this.salesCountDelta,
    required this.avgBasketDelta,
    required this.lastSevenDaysRevenue,
    required this.lastSevenDaysSeries,
  });

  static final SalesDashboardSummary empty = SalesDashboardSummary(
    revenue: Decimal.zero,
    netProfit: Decimal.zero,
    salesCount: 0,
    avgBasket: Decimal.zero,
    revenueDelta: KpiDelta.flat,
    netProfitDelta: KpiDelta.flat,
    salesCountDelta: KpiDelta.flat,
    avgBasketDelta: KpiDelta.flat,
    lastSevenDaysRevenue: Decimal.zero,
    lastSevenDaysSeries: List<Decimal>.filled(7, Decimal.zero),
  );

  /// What the store kept today, not what buyers handed over.
  final Decimal revenue;
  final Decimal netProfit;
  final int salesCount;

  /// What the average buyer handed over — the figure a shopkeeper compares
  /// against a till, so it is the buyer total rather than net revenue.
  final Decimal avgBasket;

  final KpiDelta revenueDelta;
  final KpiDelta netProfitDelta;
  final KpiDelta salesCountDelta;
  final KpiDelta avgBasketDelta;

  final Decimal lastSevenDaysRevenue;

  /// Seven daily buckets, oldest first, ending on today.
  final List<Decimal> lastSevenDaysSeries;

  @override
  List<Object?> get props => [
    revenue,
    netProfit,
    salesCount,
    avgBasket,
    revenueDelta,
    netProfitDelta,
    salesCountDelta,
    avgBasketDelta,
    lastSevenDaysRevenue,
    lastSevenDaysSeries,
  ];
}
