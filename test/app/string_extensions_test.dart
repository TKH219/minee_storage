import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/app/extensions/string_extensions.dart';

void main() {
  test('a bare domain gains an https scheme', () {
    expect(normalisedUrlOrNull('shopee.vn/linh'), 'https://shopee.vn/linh');
  });

  test('an explicit scheme is preserved', () {
    expect(normalisedUrlOrNull('http://shop.vn'), 'http://shop.vn');
  });

  test('surrounding whitespace is trimmed', () {
    expect(normalisedUrlOrNull('  shopee.vn  '), 'https://shopee.vn');
  });

  test('blank input is null, not an empty string', () {
    expect(normalisedUrlOrNull('   '), isNull);
    expect(normalisedUrlOrNull(null), isNull);
  });

  test('input that cannot resolve to a host is rejected', () {
    expect(normalisedUrlOrNull('not a url'), isNull);
  });
}
