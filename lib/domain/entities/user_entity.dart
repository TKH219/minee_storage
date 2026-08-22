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
