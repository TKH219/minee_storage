import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  const created = '2026-08-01T09:00:00.000Z';
  const updated = '2026-08-02T09:00:00.000Z';

  test('StoreModel mirrors the row and converts to the entity', () {
    final model = StoreModel.fromJson({
      'id': 's-1',
      'owner_id': 'uid-1',
      'name': 'Tạp hóa Linh',
      'category_code': 'grocery',
      'address': '12 Lê Lợi',
      'url': 'https://shopee.vn/linh',
      'currency_id': 'cur-vnd',
      'phone': '0900000000',
      'timezone': 'Asia/Ho_Chi_Minh',
      'logo_url': 'https://cdn.example/logo.png',
      'created_at': created,
      'updated_at': updated,
      'deleted_at': null,
    });

    final store = model.toEntity();

    expect(store.id, 's-1');
    expect(store.ownerId, 'uid-1');
    expect(store.name, 'Tạp hóa Linh');
    expect(store.categoryCode, 'grocery');
    expect(store.address, '12 Lê Lợi');
    expect(store.url, 'https://shopee.vn/linh');
    expect(store.currencyId, 'cur-vnd');
    expect(store.phone, '0900000000');
    expect(store.timezone, 'Asia/Ho_Chi_Minh');
    expect(store.logoUrl, 'https://cdn.example/logo.png');
    expect(store.createdTime, DateTime.parse(created));
    expect(store.updatedTime, DateTime.parse(updated));
    expect(store.deletedTime, isNull);
    expect(store.isDeleted, isFalse);
    expect(store.role, StoreRole.owner);
  });

  test('a nullable column absent from the row is simply null', () {
    final store = StoreModel.fromJson({
      'id': 's-1',
      'owner_id': 'uid-1',
      'name': 'S',
      'currency_id': 'cur-vnd',
      'timezone': 'Asia/Ho_Chi_Minh',
      'created_at': created,
      'updated_at': updated,
    }).toEntity();

    expect(store.address, isNull);
    expect(store.logoUrl, isNull);
    expect(store.categoryCode, isNull);
  });

  test('a soft-deleted row carries its stamp through', () {
    final store = StoreModel.fromJson({
      'id': 's-1', 'owner_id': 'u', 'name': 'S', 'currency_id': 'c',
      'timezone': 'Asia/Ho_Chi_Minh', 'created_at': created, 'updated_at': updated,
      'deleted_at': '2026-08-03T09:00:00.000Z',
    }).toEntity();

    expect(store.isDeleted, isTrue);
  });

  test('UserModel converts to the profile entity', () {
    final user = UserModel.fromJson({
      'id': 'uid-1',
      'email': 'maya@shop.vn',
      'full_name': 'Maya Chen',
      'avatar_url': 'https://cdn.example/a.jpg',
      'onboarding_completed_at': updated,
      'is_deactivated': false,
      'last_signed_in_at': updated,
      'created_at': created,
      'updated_at': updated,
    }).toEntity();

    expect(user.id, 'uid-1');
    expect(user.email, 'maya@shop.vn');
    expect(user.fullName, 'Maya Chen');
    expect(user.avatarUrl, 'https://cdn.example/a.jpg');
    expect(user.onboardingCompletedAt, DateTime.parse(updated));
    expect(user.isDeactivated, isFalse);
    expect(user.needsProfile, isFalse);
    expect(user.createdTime, DateTime.parse(created));
  });

  test('StoreCategoryModel converts, keeping the icon token', () {
    final category = StoreCategoryModel.fromJson({
      'code': 'grocery',
      'name_vi': 'Tạp hóa',
      'name_en': 'Grocery',
      'icon': 'basket',
      'sort_order': 10,
      'created_at': created,
      'updated_at': updated,
    }).toEntity();

    expect(category.code, 'grocery');
    expect(category.localisedName('vi'), 'Tạp hóa');
    expect(category.localisedName('en'), 'Grocery');
    expect(category.icon, 'basket');
    expect(category.sortOrder, 10);
  });

  test('CurrencyModel converts, keeping the generated id', () {
    final currency = CurrencyModel.fromJson({
      'id': 'cur-vnd',
      'code': 'VND',
      'symbol': '₫',
      'decimals': 0,
      'sort_order': 10,
      'created_at': created,
      'updated_at': updated,
    }).toEntity();

    expect(currency.id, 'cur-vnd');
    expect(currency.code, 'VND');
    expect(currency.symbol, '₫');
    expect(currency.decimals, 0);
  });
}
