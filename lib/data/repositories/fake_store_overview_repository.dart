import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/domain/repositories/store_overview_repository.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';

/// Composes the switcher's rows out of the two repositories that already exist,
/// rather than adding a count endpoint the products contract does not have.
class FakeStoreOverviewRepository implements StoreOverviewRepository {
  const FakeStoreOverviewRepository(this._stores, this._products);

  final StoreRepository _stores;
  final ProductRepository _products;

  /// One page wide enough to hold any mock catalogue. A real implementation
  /// answers with a count query instead of a page.
  static const int _countPageSize = 500;

  @override
  Future<List<StoreSummary>> summaries() async {
    final stores = await _stores.listMine();
    if (stores.isEmpty) return const [];

    final currencies = await _stores.currencies();
    final byId = {for (final currency in currencies) currency.id: currency};

    final summaries = <StoreSummary>[];
    for (final store in stores) {
      final page = await _products.getProducts(
        storeId: store.id,
        filter: const ProductFilter(),
        page: 1,
        limit: _countPageSize,
      );
      summaries.add(
        StoreSummary(
          store: store,
          currency: byId[store.currencyId] ?? Currency.vnd,
          // A product belongs to the user, not to a shop (§5.8) — only its lots
          // are store-scoped. So what a store "holds" is the products with
          // stock sitting in it, not every catalogue entry the owner has.
          productCount: page.items.where((product) => product.hasStock).length,
        ),
      );
    }
    return summaries;
  }
}
