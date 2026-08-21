import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('builds from a users row', () {
    final user = UserEntity.fromRow({
      'id': 'uid-1',
      'email': 'a@b.com',
      'full_name': 'Linh Nguyen',
      'avatar_url': 'https://cdn.example/x.jpg',
      'onboarding_completed_at': '2026-08-21T10:00:00.000Z',
      'is_deactivated': false,
      'last_signed_in_at': '2026-08-09T10:00:00.000Z',
    });

    expect(user.id, 'uid-1');
    expect(user.email, 'a@b.com');
    expect(user.fullName, 'Linh Nguyen');
    expect(user.avatarUrl, 'https://cdn.example/x.jpg');
    expect(user.onboardingCompletedAt, DateTime.parse('2026-08-21T10:00:00.000Z'));
    expect(user.isDeactivated, isFalse);
    expect(user.lastSignedInAt, DateTime.parse('2026-08-09T10:00:00.000Z'));
    expect(user.needsProfile, isFalse);
  });

  test('tolerates a row with nulls', () {
    final user = UserEntity.fromRow({'id': 'uid-2'});

    expect(user.email, '');
    expect(user.fullName, '');
    expect(user.avatarUrl, isNull);
    expect(user.onboardingCompletedAt, isNull);
    expect(user.isDeactivated, isFalse);
    expect(user.lastSignedInAt, isNull);
  });

  test('a blank full name means the profile step is still owed', () {
    final user = UserEntity.fromRow({'id': 'uid-1', 'email': 'a@b.c', 'full_name': '   '});

    expect(user.needsProfile, isTrue);
  });

  test('equality is by value', () {
    const a = UserEntity(id: '1', email: 'a@b.com', fullName: 'Linh');
    const b = UserEntity(id: '1', email: 'a@b.com', fullName: 'Linh');

    expect(a, b);
  });
}
