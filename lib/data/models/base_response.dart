import 'package:json_annotation/json_annotation.dart';

part 'base_response.g.dart';

/// Envelope used by the Mine Storage backend: `{ code, message, data }`.
///
/// Declare a Retrofit endpoint as `Future<BaseResponse<LoginResponse>>` and the
/// generator wires the nested `fromJson` automatically.
///
/// The demo `PostApi` does not use this — jsonplaceholder returns bare arrays.
@JsonSerializable(genericArgumentFactories: true)
class BaseResponse<T> {
  const BaseResponse({this.code, this.message, this.data});

  factory BaseResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? json) fromJsonT,
  ) => _$BaseResponseFromJson(json, fromJsonT);

  final String? code;
  final String? message;
  final T? data;

  Map<String, dynamic> toJson(Object? Function(T value) toJsonT) =>
      _$BaseResponseToJson(this, toJsonT);
}
