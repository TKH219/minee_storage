import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('a blank full name means the profile step is still owed', () {
    const user = UserEntity(id: 'uid-1', email: 'a@b.c');

    expect(user.needsProfile, isTrue);
  });

  test('whitespace is not a name', () {
    const user = UserEntity(id: 'uid-1', email: 'a@b.c', fullName: '   ');

    expect(user.needsProfile, isTrue);
  });

  test('a real name settles it', () {
    const user = UserEntity(id: 'uid-1', email: 'a@b.c', fullName: 'Maya Chen');

    expect(user.needsProfile, isFalse);
  });

  test('equality is by value', () {
    const a = UserEntity(id: '1', email: 'a@b.com', fullName: 'Maya');
    const b = UserEntity(id: '1', email: 'a@b.com', fullName: 'Maya');

    expect(a, b);
  });
}
