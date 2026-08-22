import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/store_data_source_impl.dart';

import '../support/fake_store_api.dart';
import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('fetchMine speaks PostgREST filter grammar', () async {
    final api = FakeStoreApi();
    final source = StoreDataSourceImpl(api, currentUserId: () => 'uid-1');

    await source.fetchMine('uid-1');

    expect(api.lastQuery['owner_id'], 'eq.uid-1');
    expect(api.lastQuery['is_archived'], 'eq.false');
    expect(api.lastQuery['order'], 'created_at.asc');
  });

  test('reference tables come back ordered by sort_order', () async {
    final api = FakeStoreApi();
    final source = StoreDataSourceImpl(api, currentUserId: () => 'uid-1');

    await source.fetchCategories();
    await source.fetchCurrencies();

    expect(api.lastQuery['categories_order'], 'sort_order.asc');
    expect(api.lastQuery['currencies_order'], 'sort_order.asc');
  });

  test('insert returns the single created row, not the array PostgREST sends', () async {
    final api = FakeStoreApi();
    final source = StoreDataSourceImpl(api, currentUserId: () => 'uid-1');

    final row = await source.insertStore({'name': 'Tạp hóa Linh'});

    expect(row['id'], 's-new');
    expect(row['name'], 'Tạp hóa Linh');
    expect(api.inserted['name'], 'Tạp hóa Linh');
  });

  test('an insert that returns nothing is a server error, not a crash', () async {
    final api = _EmptyInsertApi();
    final source = StoreDataSourceImpl(api, currentUserId: () => 'uid-1');

    expect(
      () => source.insertStore({'name': 'S'}),
      throwsA(isA<ServerException>()),
    );
  });

  test('the current user id comes from the injected session getter', () {
    final source = StoreDataSourceImpl(FakeStoreApi(), currentUserId: () => 'uid-9');

    expect(source.currentUserId, 'uid-9');
  });
}

class _EmptyInsertApi extends FakeStoreApi {
  @override
  Future<dynamic> insertStore(Map<String, dynamic> values) async => <dynamic>[];
}
