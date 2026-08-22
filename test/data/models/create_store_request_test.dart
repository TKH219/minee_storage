import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/models/models.dart';

void main() {
  test('serialises to the stores column names', () {
    const request = CreateStoreRequest(
      ownerId: 'uid-1',
      name: 'Tạp hóa Linh',
      categoryCode: 'grocery',
      currencyId: 'cur-vnd',
      address: '12 Lê Lợi',
      url: 'https://shopee.vn/linh',
      logoUrl: 'https://cdn.example/logo.png',
    );

    expect(request.toJson(), {
      'owner_id': 'uid-1',
      'name': 'Tạp hóa Linh',
      'category_code': 'grocery',
      'currency_id': 'cur-vnd',
      'address': '12 Lê Lợi',
      'url': 'https://shopee.vn/linh',
      'logo_url': 'https://cdn.example/logo.png',
    });
  });

  test('omits the optional fields it was not given', () {
    const request = CreateStoreRequest(
      ownerId: 'uid-1',
      name: 'S',
      categoryCode: 'other',
      currencyId: 'cur-vnd',
    );

    expect(request.toJson(), {
      'owner_id': 'uid-1',
      'name': 'S',
      'category_code': 'other',
      'currency_id': 'cur-vnd',
    });
  });

  test('an omitted optional is absent, so the column keeps its own default', () {
    const request = CreateStoreRequest(
      ownerId: 'uid-1',
      name: 'S',
      categoryCode: 'other',
      currencyId: 'cur-vnd',
    );

    expect(request.toJson().containsKey('address'), isFalse);
    expect(request.toJson().containsKey('url'), isFalse);
    expect(request.toJson().containsKey('logo_url'), isFalse);
  });
}
