import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('a store you can see is a store you own', () {
    const store = Store(id: 's-1', ownerId: 'uid-1', name: 'S');

    expect(store.role, StoreRole.owner);
  });

  test('timezone defaults to Ho Chi Minh', () {
    const store = Store(id: 's-1', ownerId: 'uid-1', name: 'S');

    expect(store.timezone, 'Asia/Ho_Chi_Minh');
  });

  test('equality is by value', () {
    const a = Store(id: 's-1', ownerId: 'uid-1', name: 'S', currencyId: 'c');
    const b = Store(id: 's-1', ownerId: 'uid-1', name: 'S', currencyId: 'c');

    expect(a, b);
  });

  test('a different currency makes a different store', () {
    const a = Store(id: 's-1', ownerId: 'uid-1', name: 'S', currencyId: 'cur-vnd');
    const b = Store(id: 's-1', ownerId: 'uid-1', name: 'S', currencyId: 'cur-usd');

    expect(a, isNot(b));
  });

  test('a category localises to the active language', () {
    const category = StoreCategory(
      code: 'grocery', nameVi: 'Tạp hóa', nameEn: 'Grocery', icon: 'basket', sortOrder: 10,
    );

    expect(category.localisedName('vi'), 'Tạp hóa');
    expect(category.localisedName('en'), 'Grocery');
  });
}
