// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'authentication_entity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AuthenticationEntity _$AuthenticationEntityFromJson(
  Map<String, dynamic> json,
) => AuthenticationEntity(
  userId: json['userId'] as String,
  accessToken: json['accessToken'] as String,
  refreshToken: json['refreshToken'] as String,
);

Map<String, dynamic> _$AuthenticationEntityToJson(
  AuthenticationEntity instance,
) => <String, dynamic>{
  'userId': instance.userId,
  'accessToken': instance.accessToken,
  'refreshToken': instance.refreshToken,
};
