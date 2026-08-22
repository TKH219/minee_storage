import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'store_model.g.dart';

/// A row of `public.stores`. Mirrors the columns exactly; [toEntity] is the
/// only place the domain learns about the wire format.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class StoreModel {
  const StoreModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.currencyId,
    required this.timezone,
    required this.createdAt,
    required this.updatedAt,
    this.categoryCode,
    this.address,
    this.url,
    this.phone,
    this.logoUrl,
    this.deletedAt,
  });

  factory StoreModel.fromJson(Map<String, dynamic> json) => _$StoreModelFromJson(json);

  final String id;
  final String ownerId;
  final String name;
  final String currencyId;
  final String timezone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? categoryCode;
  final String? address;
  final String? url;
  final String? phone;
  final String? logoUrl;
  final DateTime? deletedAt;

  /// [Store.role] is always owner: row-level security only ever returns rows
  /// whose `owner_id` is the caller.
  Store toEntity() => Store(
    id: id,
    ownerId: ownerId,
    name: name,
    categoryCode: categoryCode,
    address: address,
    url: url,
    currencyId: currencyId,
    phone: phone,
    timezone: timezone,
    logoUrl: logoUrl,
    createdTime: createdAt,
    updatedTime: updatedAt,
    deletedTime: deletedAt,
  );
}
