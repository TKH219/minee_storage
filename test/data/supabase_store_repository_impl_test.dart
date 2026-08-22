import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/supabase_store_repository_impl.dart';

import '../support/fake_store_data_source.dart';
import '../support/localization_test_harness.dart';

void main() {
  setUp(useLocale);

  test('create writes the owner id and trims the free-text fields', () async {
    final source = FakeStoreDataSource();
    final repository = SupabaseStoreRepositoryImpl(source);

    await repository.create(
      name: '  Tạp hóa Linh  ',
      categoryCode: 'grocery',
      currencyId: 'cur-vnd',
      address: '  12 Lê Lợi  ',
      url: 'shopee.vn/linh',
    );

    expect(source.inserted['owner_id'], 'uid-1');
    expect(source.inserted['name'], 'Tạp hóa Linh');
    expect(source.inserted['category_code'], 'grocery');
    expect(source.inserted['currency_id'], 'cur-vnd');
    expect(source.inserted['address'], '12 Lê Lợi');
    expect(source.inserted['url'], 'https://shopee.vn/linh');
  });

  test('a blank optional field is stored as null, not an empty string', () async {
    final source = FakeStoreDataSource();
    final repository = SupabaseStoreRepositoryImpl(source);

    await repository.create(
      name: 'S',
      categoryCode: 'other',
      currencyId: 'cur-vnd',
      address: '   ',
      url: '',
    );

    expect(source.inserted['address'], isNull);
    expect(source.inserted['url'], isNull);
    expect(source.inserted['logo_url'], isNull);
  });

  test('create returns the stored row as an entity', () async {
    final repository = SupabaseStoreRepositoryImpl(FakeStoreDataSource());

    final store = await repository.create(
      name: 'Tạp hóa Linh',
      categoryCode: 'grocery',
      currencyId: 'cur-vnd',
    );

    expect(store.id, 's-new');
    expect(store.name, 'Tạp hóa Linh');
  });

  test('categories arrive sorted by sort order', () async {
    final source = FakeStoreDataSource(categoryRows: [
      {'code': 'other', 'name_vi': 'Khác', 'name_en': 'Other', 'icon': 'other', 'sort_order': 130},
      {'code': 'grocery', 'name_vi': 'Tạp hóa', 'name_en': 'Grocery', 'icon': 'basket', 'sort_order': 10},
    ]);

    final categories = await SupabaseStoreRepositoryImpl(source).categories();

    expect(categories.map((c) => c.code), ['grocery', 'other']);
  });

  test('listMine scopes to the signed-in owner', () async {
    final source = FakeStoreDataSource(storeRows: [
      {'id': 's-1', 'owner_id': 'uid-1', 'name': 'Tạp hóa Linh'},
    ]);

    final stores = await SupabaseStoreRepositoryImpl(source).listMine();

    expect(source.calls, contains('fetchMine:uid-1'));
    expect(stores.single.name, 'Tạp hóa Linh');
  });

  test('listMine without a session is empty rather than an error', () async {
    final source = FakeStoreDataSource(currentId: null);

    expect(await SupabaseStoreRepositoryImpl(source).listMine(), isEmpty);
    expect(source.calls, isEmpty);
  });

  test('creating without a session is refused', () async {
    final repository = SupabaseStoreRepositoryImpl(FakeStoreDataSource(currentId: null));

    expect(
      () => repository.create(name: 'S', categoryCode: 'other', currencyId: 'cur-vnd'),
      throwsA(isA<UnauthorizedException>()),
    );
  });

  test('currencies arrive sorted by sort order', () async {
    final source = FakeStoreDataSource(currencyRows: [
      {'code': 'USD', 'symbol': r'$', 'decimals': 2, 'sort_order': 20},
      {'code': 'VND', 'symbol': '₫', 'decimals': 0, 'sort_order': 10},
    ]);

    final currencies = await SupabaseStoreRepositoryImpl(source).currencies();

    expect(currencies.map((c) => c.code), ['VND', 'USD']);
    expect(currencies.first.decimals, 0);
  });

  test('a REST failure keeps the typed exception the interceptor produced', () async {
    // ErrorInterceptor rejects with a DioException carrying the AppException;
    // wrapping that again would flatten a network error into "unknown".
    final source = FakeStoreDataSource(
      error: DioException(
        requestOptions: RequestOptions(path: '/rest/v1/stores'),
        error: const NetworkException(message: 'offline'),
      ),
    );

    // The repository propagates it untouched; BaseStateNotifier is what
    // unwraps DioException.error into the typed exception the user sees.
    await expectLater(
      () => SupabaseStoreRepositoryImpl(source).categories(),
      throwsA(
        isA<DioException>().having((e) => e.error, 'error', isA<NetworkException>()),
      ),
    );
  });
}
