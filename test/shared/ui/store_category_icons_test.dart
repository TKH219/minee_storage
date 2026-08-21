import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/shared/ui/store_category_icons.dart';

void main() {
  const seeded = [
    'basket', 'storefront', 'restaurant', 'cafe', 'food_court', 'warehouse',
    'apparel', 'cosmetics', 'pharmacy', 'electronics', 'stationery', 'online', 'other',
  ];

  test('every seeded token maps to a distinct icon', () {
    final icons = seeded.map(iconForCategory).toSet();

    expect(icons.length, seeded.length);
  });

  test('an unknown token falls back instead of throwing', () {
    expect(
      iconForCategory('token_added_to_the_db_after_this_build'),
      iconForCategory('other'),
    );
  });

  test('an empty token falls back too', () {
    expect(iconForCategory(''), iconForCategory('other'));
  });
}
