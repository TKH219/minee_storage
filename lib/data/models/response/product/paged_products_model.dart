import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/data/models/response/product/product_model.dart';
import 'package:mine_storage/domain/entities/entities.dart';

part 'paged_products_model.g.dart';

@JsonSerializable(createToJson: false)
class PagedProductsModel {
  const PagedProductsModel({required this.items, required this.hasMore});

  factory PagedProductsModel.fromJson(Map<String, dynamic> json) =>
      _$PagedProductsModelFromJson(json);

  final List<ProductModel> items;
  final bool hasMore;

  PagedProducts toEntity() => PagedProducts(
    items: items.map((item) => item.toEntity()).toList(),
    hasMore: hasMore,
  );
}
