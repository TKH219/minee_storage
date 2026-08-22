import 'package:json_annotation/json_annotation.dart';

import 'package:mine_storage/domain/entities/entities.dart';

part 'user_model.g.dart';

/// A row of `public.users` — the profile table.
@JsonSerializable(createToJson: false, fieldRename: FieldRename.snake)
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.isDeactivated,
    required this.createdAt,
    required this.updatedAt,
    this.avatarUrl,
    this.onboardingCompletedAt,
    this.lastSignedInAt,
    this.deletedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) => _$UserModelFromJson(json);

  final String id;
  final String email;
  final String fullName;
  final bool isDeactivated;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? avatarUrl;
  final DateTime? onboardingCompletedAt;
  final DateTime? lastSignedInAt;
  final DateTime? deletedAt;

  UserEntity toEntity() => UserEntity(
    id: id,
    email: email,
    fullName: fullName,
    avatarUrl: avatarUrl,
    onboardingCompletedAt: onboardingCompletedAt,
    isDeactivated: isDeactivated,
    lastSignedInAt: lastSignedInAt,
    createdTime: createdAt,
    updatedTime: updatedAt,
    deletedTime: deletedAt,
  );
}
