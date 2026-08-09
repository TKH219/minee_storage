import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  test('builds from a users row', () {
    final user = UserEntity.fromRow({
      'id': 'uid-1',
      'email': 'a@b.com',
      'shop_name': 'Minee Storage',
      'is_deactivated': false,
      'last_signed_in_at': '2026-08-09T10:00:00.000Z',
    });

    expect(user.id, 'uid-1');
    expect(user.email, 'a@b.com');
    expect(user.shopName, 'Minee Storage');
    expect(user.isDeactivated, isFalse);
    expect(user.lastSignedInAt, DateTime.parse('2026-08-09T10:00:00.000Z'));
  });

  test('tolerates a row with nulls', () {
    final user = UserEntity.fromRow({'id': 'uid-2'});

    expect(user.email, '');
    expect(user.shopName, '');
    expect(user.isDeactivated, isFalse);
    expect(user.lastSignedInAt, isNull);
  });

  test('equality is by value', () {
    const a = UserEntity(id: '1', email: 'a@b.com', shopName: 'S');
    const b = UserEntity(id: '1', email: 'a@b.com', shopName: 'S');

    expect(a, b);
  });
}
