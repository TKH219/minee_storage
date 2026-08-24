import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'product_request.g.dart';

@JsonSerializable(createFactory: false, includeIfNull: false)
class ProductRequest {
  const ProductRequest({
    required this.name,
    required this.unit,
    required this.storeId,
    this.barcode,
    this.brand,
    this.category,
    this.notes,
    this.photoUrl,
  });

  factory ProductRequest.fromDraft(ProductDraft draft, {required String storeId}) =>
      ProductRequest(
        name: draft.name,
        unit: draft.unit.code,
        storeId: storeId,
        barcode: draft.barcode,
        brand: draft.brand,
        category: draft.category,
        notes: draft.notes,
        photoUrl: draft.photoUrl,
      );

  final String name;
  final String unit;

  /// Names the store whose stock the response should carry — a product itself
  /// belongs to no store.
  final String storeId;
  final String? barcode;
  final String? brand;
  final String? category;
  final String? notes;
  final String? photoUrl;

  Map<String, dynamic> toJson() => _$ProductRequestToJson(this);
}
