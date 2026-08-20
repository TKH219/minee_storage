import 'package:flutter_test/flutter_test.dart';

import 'auth_test_harness.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('test router starts at splash and navigates by name', () {
    final router = buildTestRouter();

    expect(currentPath(router), '/');

    router.goNamed('home');

    expect(currentPath(router), '/home');
  });
}
