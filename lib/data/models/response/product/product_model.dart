import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/data/models/response/product/product_batch_model.dart';
import 'package:mine_storage/domain/entities/entities.dart';

part 'product_model.g.dart';

@JsonSerializable(createToJson: false)
class ProductModel {
  const ProductModel({
    required this.id,
    required this.name,
    required this.isArchived,
    required this.createdAt,
    required this.updatedAt,
    this.barcode,
    this.brand,
    this.category,
    this.storageLocation,
    this.notes,
    this.photoUrl,
    this.batches = const [],
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) => _$ProductModelFromJson(json);

  final String id;
  final String name;
  final bool isArchived;
  final String createdAt;
  final String updatedAt;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? storageLocation;
  final String? notes;
  final String? photoUrl;
  final List<ProductBatchModel> batches;

  ProductEntity toEntity() => ProductEntity(
    id: id,
    name: name,
    createdAt: DateTime.parse(createdAt),
    updatedAt: DateTime.parse(updatedAt),
    barcode: barcode,
    brand: brand,
    category: category,
    storageLocation: storageLocation,
    notes: notes,
    photoUrl: photoUrl,
    isArchived: isArchived,
    batches: batches.map((batch) => batch.toEntity()).toList(),
  );
}
