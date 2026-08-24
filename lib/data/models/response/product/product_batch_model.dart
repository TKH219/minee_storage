import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'product_batch_model.g.dart';

@JsonSerializable(createToJson: false)
class ProductBatchModel {
  const ProductBatchModel({
    required this.id,
    required this.productId,
    required this.storeId,
    required this.batchCode,
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.createdAt,
    required this.updatedAt,
    this.expiryDate,
    this.supplier,
    this.storageLocation,
    this.note,
    this.deletedAt,
  });

  factory ProductBatchModel.fromJson(Map<String, dynamic> json) =>
      _$ProductBatchModelFromJson(json);

  final String id;
  final String productId;
  final String storeId;
  final String batchCode;
  final String purchasedAt;

  /// Decimals travel as strings so a NUMERIC column round-trips exactly.
  final String unitPrice;

  /// Null for goods the shop does not date.
  final String? expiryDate;
  final String initialQuantity;
  final String remainingQuantity;
  final String? supplier;
  final String? storageLocation;
  final String? note;
  final String createdAt;
  final String updatedAt;
  final String? deletedAt;

  ProductBatchEntity toEntity() => ProductBatchEntity(
    id: id,
    productId: productId,
    storeId: storeId,
    batchCode: batchCode,
    purchasedAt: DateTime.parse(purchasedAt),
    unitPrice: Decimal.parse(unitPrice),
    expiryDate: expiryDate == null ? null : DateTime.parse(expiryDate!),
    initialQuantity: Decimal.parse(initialQuantity),
    remainingQuantity: Decimal.parse(remainingQuantity),
    supplier: supplier,
    storageLocation: storageLocation,
    note: note,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    deletedAt: deletedAt == null ? null : DateTime.parse(deletedAt!),
  );
}
