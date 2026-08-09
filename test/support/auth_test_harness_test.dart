import 'package:flutter_test/flutter_test.dart';

import 'auth_test_harness.dart';

void main() {
  test('test router starts at splash and navigates by name', () {
    final router = buildTestRouter();

    expect(currentPath(router), '/');

    router.goNamed('home');

    expect(currentPath(router), '/home');
  });
}
