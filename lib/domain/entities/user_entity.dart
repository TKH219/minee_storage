import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:equatable/equatable.dart';

class UserEntity extends Equatable with AuditTimes {
  const UserEntity({
    required this.id,
    required this.email,
    this.fullName = '',
    this.avatarUrl,
    this.onboardingCompletedAt,
    this.isDeactivated = false,
    this.lastSignedInAt,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  /// Builds from a `public.users` row as PostgREST returns it.
  factory UserEntity.fromRow(Map<String, dynamic> row) {
    DateTime? parse(String key) {
      final raw = row[key] as String?;
      return raw == null ? null : DateTime.parse(raw);
    }

    return UserEntity(
      id: row['id'] as String,
      email: (row['email'] as String?) ?? '',
      fullName: (row['full_name'] as String?) ?? '',
      avatarUrl: row['avatar_url'] as String?,
      onboardingCompletedAt: parse('onboarding_completed_at'),
      isDeactivated: (row['is_deactivated'] as bool?) ?? false,
      lastSignedInAt: parse('last_signed_in_at'),
      createdTime: parse('created_at'),
      updatedTime: parse('updated_at'),
      deletedTime: parse('deleted_at'),
    );
  }

  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final DateTime? onboardingCompletedAt;
  final bool isDeactivated;
  final DateTime? lastSignedInAt;
  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  bool get needsProfile => fullName.trim().isEmpty;

  @override
  List<Object?> get props => [
    id,
    email,
    fullName,
    avatarUrl,
    onboardingCompletedAt,
    isDeactivated,
    lastSignedInAt,
    createdTime,
    updatedTime,
    deletedTime,
  ];
}
