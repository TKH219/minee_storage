import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/data/repositories/fake_store_overview_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';

import '../support/fake_store_repository.dart';

const usd = Currency(id: 'cur-usd', code: 'USD', symbol: r'$', decimals: 2);
const vnd = Currency(id: 'cur-vnd', code: 'VND', symbol: '₫', decimals: 0);

FakeStoreOverviewRepository repositoryWith(List<Store> stores) {
  return FakeStoreOverviewRepository(
    FakeStoreRepository(stores: stores, currencyList: const [usd, vnd]),
    FakeProductRepository(latency: Duration.zero, seedStoreId: 'store-a'),
  );
}

void main() {
  test('a summary carries the store, its currency and its product count', () async {
    final summaries = await repositoryWith([
      storeFixture(id: 'store-a', name: 'Northside · Main', currencyId: 'cur-usd'),
    ]).summaries();

    expect(summaries.single.store.name, 'Northside · Main');
    expect(summaries.single.currency.code, 'USD');
    expect(summaries.single.productCount, 3);
  });

  test('a store holding no stock reports a count of zero, not an error', () async {
    final summaries = await repositoryWith([
      storeFixture(id: 'store-b', name: 'Riverside Kiosk', currencyId: 'cur-vnd'),
    ]).summaries();

    expect(summaries.single.productCount, 0);
    expect(summaries.single.currency.code, 'VND');
  });

  test('a store whose currency id is unknown falls back to the default', () async {
    final summaries = await repositoryWith([
      storeFixture(id: 'store-a', currencyId: 'cur-missing'),
    ]).summaries();

    expect(summaries.single.currency.code, Currency.vnd.code);
  });

  test('the summary reports the role held in that store', () async {
    final summaries = await repositoryWith([
      storeFixture(id: 'store-a', currencyId: 'cur-usd'),
    ]).summaries();

    expect(summaries.single.role, StoreRole.owner);
  });

  test('summaries keep the order the store repository answered in', () async {
    final summaries = await repositoryWith([
      storeFixture(id: 'store-a', name: 'Main', currencyId: 'cur-usd'),
      storeFixture(id: 'store-b', name: 'Depot', currencyId: 'cur-usd'),
    ]).summaries();

    expect(summaries.map((summary) => summary.store.name), ['Main', 'Depot']);
  });

  test('no stores means no summaries', () async {
    expect(await repositoryWith(const []).summaries(), isEmpty);
  });
}
