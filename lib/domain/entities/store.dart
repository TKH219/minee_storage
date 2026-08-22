import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:equatable/equatable.dart';

enum StoreRole { owner, manager, staff }

class Store extends Equatable with AuditTimes {
  const Store({
    required this.id,
    required this.ownerId,
    required this.name,
    this.categoryCode,
    this.address,
    this.url,
    this.currencyId = '',
    this.phone,
    this.timezone = 'Asia/Ho_Chi_Minh',
    this.logoUrl,
    this.role = StoreRole.owner,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  /// Builds from a `public.stores` row as PostgREST returns it.
  ///
  /// [role] is always owner: row-level security only ever returns rows whose
  /// `owner_id` is the caller. Memberships arrive with the roles feature.
  factory Store.fromRow(Map<String, dynamic> row) => Store(
    id: row['id'] as String,
    ownerId: (row['owner_id'] as String?) ?? '',
    name: (row['name'] as String?) ?? '',
    categoryCode: row['category_code'] as String?,
    address: row['address'] as String?,
    url: row['url'] as String?,
    currencyId: (row['currency_id'] as String?) ?? '',
    phone: row['phone'] as String?,
    timezone: (row['timezone'] as String?) ?? 'Asia/Ho_Chi_Minh',
    logoUrl: row['logo_url'] as String?,
    createdTime: parseTime(row, 'created_at'),
    updatedTime: parseTime(row, 'updated_at'),
    deletedTime: parseTime(row, 'deleted_at'),
  );

  final String id;
  final String ownerId;
  final String name;
  final String? categoryCode;
  final String? address;
  final String? url;
  final String currencyId;
  final String? phone;
  final String timezone;
  final String? logoUrl;
  final StoreRole role;

  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  @override
  List<Object?> get props => [
    id,
    ownerId,
    name,
    categoryCode,
    address,
    url,
    currencyId,
    phone,
    timezone,
    logoUrl,
    role,
    createdTime,
    updatedTime,
    deletedTime,
  ];
}
