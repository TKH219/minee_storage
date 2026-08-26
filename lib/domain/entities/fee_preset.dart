import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:mine_storage/domain/entities/fee.dart';

/// A fee a store applies often enough to keep. Seeded per store with VAT and
/// Shipping; there is no screen to curate them yet.
class FeePreset extends Equatable with AuditTimes {
  const FeePreset({
    required this.id,
    required this.storeId,
    required this.name,
    required this.direction,
    required this.kind,
    required this.value,
    this.isDefault = false,
    this.sortOrder = 0,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  final String id;
  final String storeId;
  final String name;
  final FeeDirection direction;
  final FeeKind kind;
  final Decimal value;

  /// Applied to a new transaction without being asked for.
  final bool isDefault;
  final int sortOrder;

  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  Fee toFee() =>
      Fee(id: id, name: name, kind: kind, value: value, direction: direction);

  @override
  List<Object?> get props => [
    id,
    storeId,
    name,
    direction,
    kind,
    value,
    isDefault,
    sortOrder,
  ];
}
