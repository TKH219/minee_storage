import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'store_category_model.g.dart';

/// A row of `public.store_categories`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class StoreCategoryModel {
  const StoreCategoryModel({
    required this.code,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory StoreCategoryModel.fromJson(Map<String, dynamic> json) =>
      _$StoreCategoryModelFromJson(json);

  final String code;
  final String nameVi;
  final String nameEn;
  final String icon;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  StoreCategory toEntity() => StoreCategory(
    code: code,
    nameVi: nameVi,
    nameEn: nameEn,
    icon: icon,
    sortOrder: sortOrder,
    createdTime: createdAt,
    updatedTime: updatedAt,
    deletedTime: deletedAt,
  );
}
