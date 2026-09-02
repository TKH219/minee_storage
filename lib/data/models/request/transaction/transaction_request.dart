import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/data/models/response/transaction/transaction_model.dart';
import 'package:mine_storage/domain/entities/entities.dart';

part 'transaction_request.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class TransactionBatchRequest {
  const TransactionBatchRequest({
    this.batchCode,
    this.expiryDate,
    this.supplier,
    this.storageLocation,
    this.note,
  });

  factory TransactionBatchRequest.fromDraft(TransactionBatchDraft draft) =>
      TransactionBatchRequest(
        batchCode: draft.batchCode,
        expiryDate: draft.expiryDate?.toIso8601String().split('T').first,
        supplier: draft.supplier,
        storageLocation: draft.storageLocation,
        note: draft.note,
      );

  final String? batchCode;
  final String? expiryDate;
  final String? supplier;
  final String? storageLocation;
  final String? note;

  Map<String, dynamic> toJson() => _$TransactionBatchRequestToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class TransactionLineRequest {
  const TransactionLineRequest({
    required this.productId,
    required this.quantity,
    this.batchId,
    this.unitPrice,
    this.batch,
  });

  factory TransactionLineRequest.fromDraft(TransactionLineDraft draft) =>
      TransactionLineRequest(
        productId: draft.productId,
        batchId: draft.batchId,
        // Always positive on the wire. The server applies the sign from the
        // type, so a client can never file a movement in the wrong direction.
        quantity: draft.quantity.toString(),
        unitPrice: draft.unitPrice?.toString(),
        batch: draft.batch == null
            ? null
            : TransactionBatchRequest.fromDraft(draft.batch!),
      );

  final String productId;
  final String? batchId;
  final String quantity;
  final String? unitPrice;
  @JsonKey(toJson: _batchToJson)
  final TransactionBatchRequest? batch;

  Map<String, dynamic> toJson() => _$TransactionLineRequestToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class TransactionFeeRequest {
  const TransactionFeeRequest({
    required this.name,
    required this.direction,
    required this.kind,
    required this.value,
    this.isPassThrough = false,
    this.sortOrder = 0,
  });

  factory TransactionFeeRequest.fromFee(Fee fee, {int sortOrder = 0}) =>
      TransactionFeeRequest(
        name: fee.name,
        direction: feeDirectionToWire(fee.direction),
        kind: feeKindToWire(fee.kind),
        value: fee.value.toString(),
        isPassThrough: fee.direction.isPassThrough,
        sortOrder: sortOrder,
      );

  final String name;
  final String direction;
  final String kind;
  final String value;
  final bool isPassThrough;
  final int sortOrder;

  Map<String, dynamic> toJson() => _$TransactionFeeRequestToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class TransactionRequest {
  const TransactionRequest({
    required this.storeId,
    required this.type,
    required this.lines,
    this.occurredAt,
    this.fees = const [],
    this.counterparty,
    this.counterpartyPhone,
    this.note,
    this.paymentMethod,
    this.reason,
    this.reasonNote,
    this.expectedUpdatedAt,
  });

  /// [expectedUpdatedAt] carries the optimistic lock on an amend. It is absent
  /// on a create, where there is nothing yet to conflict with.
  factory TransactionRequest.fromDraft(
    TransactionDraft draft, {
    DateTime? expectedUpdatedAt,
  }) {
    var order = 0;
    return TransactionRequest(
      storeId: draft.storeId,
      type: draft.type.wireValue,
      occurredAt: draft.occurredAt?.toUtc().toIso8601String(),
      lines: [
        for (final line in draft.lines) TransactionLineRequest.fromDraft(line),
      ],
      fees: [
        for (final fee in draft.fees)
          TransactionFeeRequest.fromFee(fee, sortOrder: order++),
      ],
      counterparty: draft.counterparty,
      counterpartyPhone: draft.counterpartyPhone,
      note: draft.note,
      paymentMethod: draft.paymentMethod?.wireValue,
      reason: draft.reason?.wireValue,
      reasonNote: draft.reasonNote,
      expectedUpdatedAt: expectedUpdatedAt?.toUtc().toIso8601String(),
    );
  }

  final String storeId;
  final String type;
  final String? occurredAt;
  @JsonKey(toJson: _linesToJson)
  final List<TransactionLineRequest> lines;
  @JsonKey(toJson: _feesToJson)
  final List<TransactionFeeRequest> fees;
  final String? counterparty;
  final String? counterpartyPhone;
  final String? note;
  final String? paymentMethod;
  final String? reason;
  final String? reasonNote;
  final String? expectedUpdatedAt;

  Map<String, dynamic> toJson() => _$TransactionRequestToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class RemoveTransactionRequest {
  const RemoveTransactionRequest({required this.expectedUpdatedAt});

  factory RemoveTransactionRequest.at(DateTime updatedAt) =>
      RemoveTransactionRequest(expectedUpdatedAt: updatedAt.toUtc().toIso8601String());

  final String expectedUpdatedAt;

  Map<String, dynamic> toJson() => _$RemoveTransactionRequestToJson(this);
}

@JsonSerializable(createFactory: false, includeIfNull: false)
class FeePresetRequest {
  const FeePresetRequest({
    this.storeId,
    this.name,
    this.direction,
    this.kind,
    this.value,
    this.isPassThrough,
    this.isDefault,
    this.sortOrder,
  });

  factory FeePresetRequest.fromPreset(FeePreset preset) => FeePresetRequest(
    storeId: preset.storeId,
    name: preset.name,
    direction: feeDirectionToWire(preset.direction),
    kind: feeKindToWire(preset.kind),
    value: preset.value.toString(),
    isPassThrough: preset.direction.isPassThrough,
    isDefault: preset.isDefault,
    sortOrder: preset.sortOrder,
  );

  final String? storeId;
  final String? name;
  final String? direction;
  final String? kind;
  final String? value;
  final bool? isPassThrough;
  final bool? isDefault;
  final int? sortOrder;

  Map<String, dynamic> toJson() => _$FeePresetRequestToJson(this);
}

List<Map<String, dynamic>> _linesToJson(List<TransactionLineRequest> lines) =>
    [for (final line in lines) line.toJson()];

List<Map<String, dynamic>> _feesToJson(List<TransactionFeeRequest> fees) =>
    [for (final fee in fees) fee.toJson()];

Map<String, dynamic>? _batchToJson(TransactionBatchRequest? batch) =>
    batch?.toJson();
