import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.username,
    this.email,
    this.fullName,
    this.avatarUrl,
  });

  final String id;
  final String username;
  final String? email;
  final String? fullName;
  final String? avatarUrl;

  String get displayName => fullName?.trim().isNotEmpty == true ? fullName! : username;

  @override
  List<Object?> get props => [id, username, email, fullName, avatarUrl];
}
