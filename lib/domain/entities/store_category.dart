import 'package:mine_storage/domain/entities/audit_times.dart';
import 'package:equatable/equatable.dart';

/// A row of `public.store_categories` — the shop types offered at onboarding.
class StoreCategory extends Equatable with AuditTimes {
  const StoreCategory({
    required this.code,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.sortOrder,
    this.createdTime,
    this.updatedTime,
    this.deletedTime,
  });

  final String code;
  final String nameVi;
  final String nameEn;

  /// An opaque token, mapped to an icon in the UI layer. Kept a string so a
  /// category added to the database later cannot break an older client.
  final String icon;
  final int sortOrder;

  @override
  final DateTime? createdTime;
  @override
  final DateTime? updatedTime;
  @override
  final DateTime? deletedTime;

  String localisedName(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;

  @override
  List<Object?> get props => [code, nameVi, nameEn, icon, sortOrder, createdTime, updatedTime, deletedTime];
}
