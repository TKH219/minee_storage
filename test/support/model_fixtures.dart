import 'package:mine_storage/data/models/models.dart';

/// Builders for response models, so a test names only what it asserts on.
StoreModel storeModelFixture({
  String id = 's-1',
  String ownerId = 'uid-1',
  String name = 'Tạp hóa Linh',
  String currencyId = 'cur-vnd',
  String? categoryCode = 'grocery',
  String? address,
  String? url,
  String? logoUrl,
  DateTime? deletedAt,
}) => StoreModel(
  id: id,
  ownerId: ownerId,
  name: name,
  currencyId: currencyId,
  categoryCode: categoryCode,
  address: address,
  url: url,
  logoUrl: logoUrl,
  timezone: 'Asia/Ho_Chi_Minh',
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 2),
  deletedAt: deletedAt,
);

UserModel userModelFixture({
  String id = 'uid-1',
  String email = 'a@b.com',
  String fullName = '',
  String? avatarUrl,
  DateTime? onboardingCompletedAt,
  bool isDeactivated = false,
}) => UserModel(
  id: id,
  email: email,
  fullName: fullName,
  isDeactivated: isDeactivated,
  avatarUrl: avatarUrl,
  onboardingCompletedAt: onboardingCompletedAt,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 2),
);

StoreCategoryModel categoryModelFixture({
  String code = 'grocery',
  String nameVi = 'Tạp hóa',
  String nameEn = 'Grocery',
  String icon = 'basket',
  int sortOrder = 10,
}) => StoreCategoryModel(
  code: code,
  nameVi: nameVi,
  nameEn: nameEn,
  icon: icon,
  sortOrder: sortOrder,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 2),
);

CurrencyModel currencyModelFixture({
  String id = 'cur-vnd',
  String code = 'VND',
  String symbol = '₫',
  int decimals = 0,
  int sortOrder = 10,
}) => CurrencyModel(
  id: id,
  code: code,
  symbol: symbol,
  decimals: decimals,
  sortOrder: sortOrder,
  createdAt: DateTime.utc(2026, 8, 1),
  updatedAt: DateTime.utc(2026, 8, 2),
);
