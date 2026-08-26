import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:mine_storage/domain/entities/fee.dart';

/// A fee as it was resolved against one transaction, with the amount it moved.
///
/// The wire splits [FeeDirection.passThrough] into `buyer_charge` plus
/// `isPassThrough`, because that is what the money math actually keys on: a
/// pass-through fee raises the buyer total and then comes straight back out of
/// net revenue.
class TransactionFee extends Equatable with AuditTimes {
  const TransactionFee({
    required this.id,
    required this.transactionId,
    required this.name,
    required this.direction,
    required this.kind,
    required this.value,
    required this.computedAmount,
    this.sortOrder = 0,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  final String id;
  final String transactionId;
  final String name;
  final FeeDirection direction;
  final FeeKind kind;
  final Decimal value;
  final Decimal computedAmount;
  final int sortOrder;

  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  Fee get asFee =>
      Fee(id: id, name: name, kind: kind, value: value, direction: direction);

  @override
  List<Object?> get props => [
    id,
    transactionId,
    name,
    direction,
    kind,
    value,
    computedAmount,
    sortOrder,
  ];
}
