import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/domain/entities/entities.dart';

void main() {
  final deleted = DateTime.utc(2026, 8, 3);

  group('AuditTimes is the same contract on every persisted entity', () {
    final live = <String, AuditTimes>{
      'Store': const Store(id: 's', ownerId: 'u', name: 'S'),
      'UserEntity': const UserEntity(id: 'u', email: 'a@b.c'),
      'StoreCategory': const StoreCategory(
        code: 'grocery', nameVi: 'Tạp hóa', nameEn: 'Grocery', icon: 'basket', sortOrder: 10,
      ),
      'Currency': Currency.vnd,
    };

    for (final entry in live.entries) {
      test('${entry.key} is not deleted without a stamp', () {
        expect(entry.value.deletedTime, isNull);
        expect(entry.value.isDeleted, isFalse);
      });
    }
  });

  group('a deletion stamp marks the row deleted', () {
    test('Store', () {
      expect(
        Store(id: 's', ownerId: 'u', name: 'S', deletedTime: deleted).isDeleted,
        isTrue,
      );
    });

    test('UserEntity', () {
      expect(UserEntity(id: 'u', email: 'a@b.c', deletedTime: deleted).isDeleted, isTrue);
    });

    test('StoreCategory', () {
      expect(
        StoreCategory(
          code: 'c', nameVi: 'v', nameEn: 'e', icon: 'i', sortOrder: 0,
          deletedTime: deleted,
        ).isDeleted,
        isTrue,
      );
    });

    test('Currency', () {
      expect(
        Currency(id: 'c', code: 'VND', symbol: '₫', decimals: 0, deletedTime: deleted)
            .isDeleted,
        isTrue,
      );
    });
  });
}
