import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'product_request.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ProductRequest {
  const ProductRequest({
    required this.name,
    this.barcode,
    this.brand,
    this.category,
    this.storageLocation,
    this.notes,
    this.photoUrl,
  });

  factory ProductRequest.fromDraft(ProductDraft draft) => ProductRequest(
    name: draft.name,
    barcode: draft.barcode,
    brand: draft.brand,
    category: draft.category,
    storageLocation: draft.storageLocation,
    notes: draft.notes,
    photoUrl: draft.photoUrl,
  );

  final String name;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? storageLocation;
  final String? notes;
  final String? photoUrl;

  Map<String, dynamic> toJson() => _$ProductRequestToJson(this);
}
