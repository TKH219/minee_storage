import 'package:decimal/decimal.dart';
import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'store_holding_model.g.dart';

@JsonSerializable(createToJson: false)
class StoreHoldingModel {
  const StoreHoldingModel({
    required this.storeId,
    required this.storeName,
    required this.remaining,
    this.latestUnitPrice,
  });

  factory StoreHoldingModel.fromJson(Map<String, dynamic> json) =>
      _$StoreHoldingModelFromJson(json);

  final String storeId;
  final String storeName;
  final String remaining;
  final String? latestUnitPrice;

  StoreHolding toEntity() => StoreHolding(
    storeId: storeId,
    storeName: storeName,
    remaining: Decimal.parse(remaining),
    latestUnitPrice:
        latestUnitPrice == null ? null : Decimal.parse(latestUnitPrice!),
  );
}
