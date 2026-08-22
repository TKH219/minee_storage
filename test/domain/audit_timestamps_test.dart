import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  final stamps = {
    'created_at': '2026-08-01T09:00:00.000Z',
    'updated_at': '2026-08-02T09:00:00.000Z',
    'deleted_at': '2026-08-03T09:00:00.000Z',
  };

  final created = DateTime.parse('2026-08-01T09:00:00.000Z');
  final updated = DateTime.parse('2026-08-02T09:00:00.000Z');
  final deleted = DateTime.parse('2026-08-03T09:00:00.000Z');

  group('every persisted entity carries the audit timestamps', () {
    test('Store', () {
      final store = Store.fromRow({
        'id': 's-1', 'owner_id': 'uid-1', 'name': 'S', ...stamps,
      });

      expect(store.createdTime, created);
      expect(store.updatedTime, updated);
      expect(store.deletedTime, deleted);
      expect(store.isDeleted, isTrue);
    });

    test('UserEntity', () {
      final user = UserEntity.fromRow({'id': 'uid-1', 'email': 'a@b.c', ...stamps});

      expect(user.createdTime, created);
      expect(user.updatedTime, updated);
      expect(user.deletedTime, deleted);
      expect(user.isDeleted, isTrue);
    });

    test('StoreCategory', () {
      final category = StoreCategory.fromRow({'code': 'grocery', ...stamps});

      expect(category.createdTime, created);
      expect(category.updatedTime, updated);
      expect(category.deletedTime, deleted);
      expect(category.isDeleted, isTrue);
    });

    test('Currency', () {
      final currency = Currency.fromRow({'id': 'c-1', 'code': 'VND', ...stamps});

      expect(currency.createdTime, created);
      expect(currency.updatedTime, updated);
      expect(currency.deletedTime, deleted);
      expect(currency.isDeleted, isTrue);
    });
  });

  group('a live row has no deletion stamp', () {
    test('Store', () {
      final store = Store.fromRow({'id': 's-1', 'owner_id': 'u', 'name': 'S'});

      expect(store.deletedTime, isNull);
      expect(store.isDeleted, isFalse);
      expect(store.createdTime, isNull);
    });

    test('Currency', () {
      expect(Currency.vnd.isDeleted, isFalse);
    });
  });
}
