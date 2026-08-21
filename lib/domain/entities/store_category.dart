import 'package:equatable/equatable.dart';

/// A row of `public.store_categories` — the shop types offered at onboarding.
class StoreCategory extends Equatable {
  const StoreCategory({
    required this.code,
    required this.nameVi,
    required this.nameEn,
    required this.icon,
    required this.sortOrder,
  });

  factory StoreCategory.fromRow(Map<String, dynamic> row) => StoreCategory(
    code: row['code'] as String,
    nameVi: (row['name_vi'] as String?) ?? '',
    nameEn: (row['name_en'] as String?) ?? '',
    icon: (row['icon'] as String?) ?? 'other',
    sortOrder: (row['sort_order'] as int?) ?? 0,
  );

  final String code;
  final String nameVi;
  final String nameEn;

  /// An opaque token, mapped to an icon in the UI layer. Kept a string so a
  /// category added to the database later cannot break an older client.
  final String icon;
  final int sortOrder;

  String localisedName(String languageCode) => languageCode == 'vi' ? nameVi : nameEn;

  @override
  List<Object?> get props => [code, nameVi, nameEn, icon, sortOrder];
}
