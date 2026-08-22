import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'currency_model.g.dart';

/// A row of `public.currencies`.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class CurrencyModel {
  const CurrencyModel({
    required this.id,
    required this.code,
    required this.symbol,
    required this.decimals,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  factory CurrencyModel.fromJson(Map<String, dynamic> json) =>
      _$CurrencyModelFromJson(json);

  final String id;
  final String code;
  final String symbol;
  final int decimals;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? deletedAt;

  Currency toEntity() => Currency(
    id: id,
    code: code,
    symbol: symbol,
    decimals: decimals,
    sortOrder: sortOrder,
    createdTime: createdAt,
    updatedTime: updatedAt,
    deletedTime: deletedAt,
  );
}
