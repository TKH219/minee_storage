import 'package:equatable/equatable.dart';
import 'package:json_annotation/json_annotation.dart';

part 'authentication_entity.g.dart';

/// The persisted session. Serialisable because it round-trips through secure
/// storage as JSON.
@JsonSerializable()
class AuthenticationEntity extends Equatable {
  const AuthenticationEntity({
    required this.userId,
    required this.accessToken,
    required this.refreshToken,
  });

  factory AuthenticationEntity.fromJson(Map<String, dynamic> json) =>
      _$AuthenticationEntityFromJson(json);

  final String userId;
  final String accessToken;
  final String refreshToken;

  String get accessTokenHeader => 'Bearer $accessToken';

  bool get isValid => accessToken.isNotEmpty;

  AuthenticationEntity copyWith({
    String? userId,
    String? accessToken,
    String? refreshToken,
  }) {
    return AuthenticationEntity(
      userId: userId ?? this.userId,
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
    );
  }

  Map<String, dynamic> toJson() => _$AuthenticationEntityToJson(this);

  @override
  List<Object?> get props => [userId, accessToken, refreshToken];
}
