import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'product_batch_model.g.dart';

@JsonSerializable(createToJson: false)
class ProductBatchModel {
  const ProductBatchModel({
    required this.id,
    required this.productId,
    required this.purchasedAt,
    required this.unitPrice,
    required this.initialQuantity,
    required this.remainingQuantity,
    required this.isArchived,
    required this.createdAt,
    this.expiryDate,
  });

  factory ProductBatchModel.fromJson(Map<String, dynamic> json) =>
      _$ProductBatchModelFromJson(json);

  final String id;
  final String productId;
  final String purchasedAt;

  /// Decimals travel as strings so a NUMERIC column round-trips exactly.
  final String unitPrice;

  /// Null for goods the shop does not date.
  final String? expiryDate;
  final String initialQuantity;
  final String remainingQuantity;
  final bool isArchived;
  final String createdAt;

  ProductBatchEntity toEntity() => ProductBatchEntity(
    id: id,
    productId: productId,
    purchasedAt: DateTime.parse(purchasedAt),
    unitPrice: Decimal.parse(unitPrice),
    expiryDate: expiryDate == null ? null : DateTime.parse(expiryDate!),
    initialQuantity: Decimal.parse(initialQuantity),
    remainingQuantity: Decimal.parse(remainingQuantity),
    createdAt: DateTime.parse(createdAt),
    isArchived: isArchived,
  );
}
