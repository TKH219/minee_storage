import 'package:flutter_test/flutter_test.dart';
import 'package:mine_storage/data/mock/mock_database.dart';
import 'package:mine_storage/data/repositories/mock_product_repository_impl.dart';

import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  late MockProductRepositoryImpl repo;

  setUp(() {
    repo = MockProductRepositoryImpl(
      MockDatabase(today: DateTime(2026, 8, 20)),
      latency: Duration.zero,
    );
  });

  test('list hides archived products by default', () async {
    final visible = await repo.list(storeId: 'northside-main');
    expect(visible.any((p) => p.archived), isFalse);

    final all = await repo.list(storeId: 'northside-main', includeArchived: true);
    expect(all.any((p) => p.archived), isTrue);
  });

  test('query matches on name only, never on barcode', () async {
    final byName = await repo.list(storeId: 'northside-main', query: 'milk');
    expect(byName.map((p) => p.id), contains('milk'));

    final milk = await repo.byId('milk');
    final byBarcode = await repo.list(storeId: 'northside-main', query: milk.barcode!);
    expect(byBarcode, isEmpty);
  });

  test('consume mutates the store so a second read sees the new figures', () async {
    await repo.consume('milk', 6);
    expect((await repo.byId('milk')).totalRemaining, 4);
  });

  test('archive and restore round-trip through the repository', () async {
    await repo.archive('milk');
    expect((await repo.list(storeId: 'northside-main')).map((p) => p.id), isNot(contains('milk')));
    await repo.restore('milk');
    expect((await repo.list(storeId: 'northside-main')).map((p) => p.id), contains('milk'));
  });
}
