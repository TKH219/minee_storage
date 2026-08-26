import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'batch_request.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class BatchRequest {
  const BatchRequest({
    required this.storeId,
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    this.expiryDate,
    this.supplier,
    this.storageLocation,
    this.note,
  });

  factory BatchRequest.fromDraft(BatchDraft draft) => BatchRequest(
    storeId: draft.storeId,
    purchasedAt: draft.purchasedAt.toUtc().toIso8601String(),
    unitPrice: draft.unitPrice.toString(),
    expiryDate: _dateOnly(draft.expiryDate),
    initialQuantity: draft.initialQuantity.toString(),
    supplier: draft.supplier,
    storageLocation: draft.storageLocation,
    note: draft.note,
  );

  /// The column is a `date`, so sending an instant would make the row's expiry
  /// depend on the sender's clock offset.
  static String? _dateOnly(DateTime? value) {
    if (value == null) return null;
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  final String storeId;
  final String purchasedAt;
  final String unitPrice;
  final String? expiryDate;
  final String initialQuantity;
  final String? supplier;
  final String? storageLocation;
  final String? note;

  Map<String, dynamic> toJson() => _$BatchRequestToJson(this);
}
