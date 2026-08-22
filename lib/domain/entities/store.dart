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
