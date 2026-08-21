import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('fromRow maps every shop column', () {
    final store = Store.fromRow({
      'id': 's-1',
      'owner_id': 'uid-1',
      'name': 'Tạp hóa Linh',
      'category_code': 'grocery',
      'address': '12 Lê Lợi',
      'url': 'https://shopee.vn/linh',
      'currency': 'VND',
      'phone': '0900000000',
      'timezone': 'Asia/Ho_Chi_Minh',
      'logo_url': 'https://cdn.example/logo.png',
      'is_archived': false,
    });

    expect(store.id, 's-1');
    expect(store.ownerId, 'uid-1');
    expect(store.name, 'Tạp hóa Linh');
    expect(store.categoryCode, 'grocery');
    expect(store.address, '12 Lê Lợi');
    expect(store.url, 'https://shopee.vn/linh');
    expect(store.currencyCode, 'VND');
    expect(store.phone, '0900000000');
    expect(store.timezone, 'Asia/Ho_Chi_Minh');
    expect(store.logoUrl, 'https://cdn.example/logo.png');
    expect(store.isArchived, isFalse);
  });

  test('a row you can see is a row you own', () {
    final store = Store.fromRow({'id': 's-1', 'owner_id': 'uid-1', 'name': 'S'});

    expect(store.role, StoreRole.owner);
  });

  test('currency defaults to VND and timezone to Ho Chi Minh', () {
    final store = Store.fromRow({'id': 's-1', 'owner_id': 'uid-1', 'name': 'S'});

    expect(store.currencyCode, 'VND');
    expect(store.timezone, 'Asia/Ho_Chi_Minh');
  });

  test('a category localises to the active language', () {
    const category = StoreCategory(
      code: 'grocery',
      nameVi: 'Tạp hóa',
      nameEn: 'Grocery',
      icon: 'basket',
      sortOrder: 10,
    );

    expect(category.localisedName('vi'), 'Tạp hóa');
    expect(category.localisedName('en'), 'Grocery');
  });

  test('a category row tolerates missing optional values', () {
    final category = StoreCategory.fromRow({'code': 'other'});

    expect(category.code, 'other');
    expect(category.icon, 'other');
    expect(category.sortOrder, 0);
  });
}
