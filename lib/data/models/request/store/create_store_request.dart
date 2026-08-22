import 'package:json_annotation/json_annotation.dart';

part 'create_store_request.g.dart';

/// The body of `POST /rest/v1/stores`. Mirrors the column names exactly.
///
/// Optional fields are omitted rather than sent as null, so a column keeps its
/// own default instead of being overwritten with nothing.
@JsonSerializable(
  createFactory: false,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class CreateStoreRequest {
  const CreateStoreRequest({
    required this.ownerId,
    required this.name,
    required this.categoryCode,
    required this.currencyId,
    this.address,
    this.url,
    this.logoUrl,
  });

  final String ownerId;
  final String name;
  final String categoryCode;
  final String currencyId;
  final String? address;
  final String? url;
  final String? logoUrl;

  Map<String, dynamic> toJson() => _$CreateStoreRequestToJson(this);
}
