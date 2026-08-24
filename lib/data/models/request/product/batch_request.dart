import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'batch_request.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class BatchRequest {
  const BatchRequest({
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    this.expiryDate,
    this.remainingQuantity,
  });

  factory BatchRequest.fromDraft(BatchDraft draft) => BatchRequest(
    purchasedAt: draft.purchasedAt.toUtc().toIso8601String(),
    unitPrice: draft.unitPrice.toString(),
    expiryDate: draft.expiryDate?.toUtc().toIso8601String(),
    initialQuantity: draft.initialQuantity.toString(),
    remainingQuantity: draft.remainingQuantity?.toString(),
  );

  final String purchasedAt;
  final String unitPrice;
  final String? expiryDate;
  final String initialQuantity;
  final String? remainingQuantity;

  Map<String, dynamic> toJson() => _$BatchRequestToJson(this);
}
