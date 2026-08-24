import 'package:decimal/decimal.dart';
import 'package:equatable/equatable.dart';

/// A resolved instruction: take [quantity] out of batch [batchId].
class BatchAllocation extends Equatable {
  const BatchAllocation({required this.batchId, required this.quantity});

  final String batchId;
  final Decimal quantity;

  @override
  List<Object?> get props => [batchId, quantity];
}
