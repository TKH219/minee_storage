import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/repositories/fake_product_repository.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/product_repository.dart';
import 'package:mine_storage/features/products/states/product_list_state.dart';
import 'package:mine_storage/providers.dart';

void main() {
  ProviderContainer containerWith(ProductRepository repository) {
    final container = ProviderContainer(
      overrides: [productRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    // The provider is autoDispose; without a live listener it is torn down
    // between reads and every state update is discarded.
    container.listen(productListStateProvider, (_, _) {}, fireImmediately: true);
    return container;
  }

  test('loadInitial fills the list and marks it loaded', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);

    await notifier.loadInitial();

    final state = container.read(productListStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.products, isNotEmpty);
    expect(state.page, 1);
  });

  test('search narrows the list and resets to page one', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);
    await notifier.loadInitial();

    await notifier.search('olive');

    final state = container.read(productListStateProvider);
    expect(state.filter.query, 'olive');
    expect(state.page, 1);
    expect(state.products.every((p) => p.name.toLowerCase().contains('olive')), isTrue);
  });

  test('setQuickFilter replaces the previous quick filter', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);
    await notifier.loadInitial();

    await notifier.setQuickFilter(ProductQuickFilter.expired);

    expect(
      container.read(productListStateProvider).filter.quickFilter,
      ProductQuickFilter.expired,
    );
  });

  test('refresh keeps the list on screen instead of flipping to loading', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);
    await notifier.loadInitial();

    final future = notifier.refresh();
    expect(container.read(productListStateProvider).isLoading, isFalse);
    await future;

    expect(container.read(productListStateProvider).products, isNotEmpty);
  });

  test('loadMore is a no-op once the end is reached', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);
    await notifier.loadInitial();
    final before = container.read(productListStateProvider).products.length;

    await notifier.loadMore();

    expect(container.read(productListStateProvider).products, hasLength(before));
  });

  test('a failed first load shows the full screen error surface', () async {
    final container = containerWith(_FailingRepository());
    final notifier = container.read(productListStateProvider.notifier);

    await notifier.loadInitial();

    final state = container.read(productListStateProvider);
    expect(state.showFullScreenError, isTrue);
    expect(state.errorMessage, 'offline');
  });

  test('isEmpty is true only once a load has completed with no results', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);

    await notifier.search('nothing matches this');

    expect(container.read(productListStateProvider).isEmpty, isTrue);
  });

  test('a slow loadCategories does not clobber a finished load', () async {
    final container = containerWith(_SlowCategoriesRepository());
    final notifier = container.read(productListStateProvider.notifier);

    final categories = notifier.loadCategories();
    await notifier.loadInitial();
    await categories;

    final state = container.read(productListStateProvider);
    expect(state.isLoaded, isTrue);
    expect(state.products, isNotEmpty);
    expect(state.categories, isNotEmpty);
  });

  test('loadCategories populates the filter sheet source', () async {
    final container = containerWith(FakeProductRepository());
    final notifier = container.read(productListStateProvider.notifier);

    await notifier.loadCategories();

    expect(container.read(productListStateProvider).categories, contains('Pantry'));
  });
}

/// getCategories resolves after getProducts, which is what surfaced the
/// pre-await state capture in loadCategories.
class _SlowCategoriesRepository extends FakeProductRepository {
  _SlowCategoriesRepository() : super(latency: Duration.zero);

  @override
  Future<List<String>> getCategories() async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return super.getCategories();
  }
}

class _FailingRepository extends FakeProductRepository {
  @override
  Future<PagedProducts> getProducts({
    required ProductFilter filter,
    required int page,
    int limit = 20,
  }) async {
    throw const NetworkException(message: 'offline');
  }
}
