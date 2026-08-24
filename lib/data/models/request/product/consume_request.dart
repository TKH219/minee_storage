import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'consume_request.g.dart';

class ConsumeRequest {
  const ConsumeRequest({required this.allocations});

  factory ConsumeRequest.fromAllocations(List<BatchAllocation> allocations) => ConsumeRequest(
    allocations: allocations
        .map(
          (allocation) => BatchAllocationRequest(
            batchId: allocation.batchId,
            quantity: allocation.quantity.toString(),
          ),
        )
        .toList(),
  );

  final List<BatchAllocationRequest> allocations;

  /// Written by hand: json_serializable emits the nested requests as objects
  /// rather than maps, which only survives because jsonEncode happens to find
  /// their toJson at runtime.
  Map<String, dynamic> toJson() => {
    'allocations': allocations.map((allocation) => allocation.toJson()).toList(),
  };
}

@JsonSerializable(createFactory: false)
class BatchAllocationRequest {
  const BatchAllocationRequest({required this.batchId, required this.quantity});

  final String batchId;
  final String quantity;

  Map<String, dynamic> toJson() => _$BatchAllocationRequestToJson(this);
}
