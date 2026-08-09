import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  const UserEntity({
    required this.id,
    required this.email,
    required this.shopName,
    this.isDeactivated = false,
    this.lastSignedInAt,
  });

  /// Builds from a `public.users` row as PostgREST returns it.
  factory UserEntity.fromRow(Map<String, dynamic> row) {
    final signedIn = row['last_signed_in_at'] as String?;
    return UserEntity(
      id: row['id'] as String,
      email: (row['email'] as String?) ?? '',
      shopName: (row['shop_name'] as String?) ?? '',
      isDeactivated: (row['is_deactivated'] as bool?) ?? false,
      lastSignedInAt: signedIn == null ? null : DateTime.parse(signedIn),
    );
  }

  final String id;
  final String email;
  final String shopName;
  final bool isDeactivated;
  final DateTime? lastSignedInAt;

  @override
  List<Object?> get props => [id, email, shopName, isDeactivated, lastSignedInAt];
}
