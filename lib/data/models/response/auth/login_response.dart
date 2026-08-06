import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'login_response.g.dart';

@JsonSerializable(createToJson: false)
class LoginResponse {
  const LoginResponse({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) => _$LoginResponseFromJson(json);

  final String userId;
  final String accessToken;
  final String refreshToken;

  AuthenticationEntity toEntity() => AuthenticationEntity(
    userId: userId,
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
