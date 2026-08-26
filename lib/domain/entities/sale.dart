import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/payment_method.dart';
import 'package:mine_storage/domain/entities/sale_line.dart';
import 'package:mine_storage/domain/entities/sale_totals.dart';

/// A paid sale. Immutable by §5.4.5 — corrections go through a return or a
/// void, never through an edit.
class Sale extends Equatable {
  const Sale({
    required this.id,
    required this.code,
    required this.storeId,
    required this.paidAt,
    required this.lines,
    required this.totals,
    required this.paymentMethod,
    required this.deductedLotCount,
  });

  final String id;
  final String code;
  final String storeId;
  final DateTime paidAt;
  final List<SaleLine> lines;
  final SaleTotals totals;
  final PaymentMethod paymentMethod;
  final int deductedLotCount;

  @override
  List<Object?> get props => [
    id,
    code,
    storeId,
    paidAt,
    lines,
    totals,
    paymentMethod,
    deductedLotCount,
  ];
}
