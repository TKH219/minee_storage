import 'package:json_annotation/json_annotation.dart';

part 'token_refreshed_model.g.dart';

@JsonSerializable(createToJson: false)
class TokenRefreshedModel {
  const TokenRefreshedModel({required this.accessToken, required this.refreshToken});

  factory TokenRefreshedModel.fromJson(Map<String, dynamic> json) =>
      _$TokenRefreshedModelFromJson(json);

  final String accessToken;
  final String refreshToken;
}
