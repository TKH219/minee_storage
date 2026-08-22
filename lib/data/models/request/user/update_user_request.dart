import 'package:json_annotation/json_annotation.dart';

part 'update_user_request.g.dart';

/// The body of `PATCH /rest/v1/users`. Every column is optional, so one type
/// serves the profile write and both timestamp stamps — each sends only what
/// it touches, and an omitted column is left alone rather than nulled.
@JsonSerializable(
  createFactory: false,
  fieldRename: FieldRename.snake,
  includeIfNull: false,
)
class UpdateUserRequest {
  const UpdateUserRequest({
    required this.updatedAt,
    this.fullName,
    this.avatarUrl,
    this.onboardingCompletedAt,
    this.lastSignedInAt,
  });

  final DateTime updatedAt;
  final String? fullName;
  final String? avatarUrl;
  final DateTime? onboardingCompletedAt;
  final DateTime? lastSignedInAt;

  Map<String, dynamic> toJson() => _$UpdateUserRequestToJson(this);
}
