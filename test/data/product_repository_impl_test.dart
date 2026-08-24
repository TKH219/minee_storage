import 'package:decimal/decimal.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/product_api.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/data/repositories/product_repository_impl.dart';
import 'package:mine_storage/domain/entities/entities.dart';

Map<String, dynamic> productJson({String id = 'p1'}) => {
  'id': id,
  'name': 'Olive oil',
  'isArchived': false,
  'createdAt': '2026-07-01T00:00:00.000Z',
  'updatedAt': '2026-07-01T00:00:00.000Z',
  'batches': [
    {
      'id': 'b1',
      'productId': id,
      'purchasedAt': '2026-08-01T00:00:00.000Z',
      'unitPrice': '12.75',
      'expiryDate': '2026-09-01T00:00:00.000Z',
      'initialQuantity': '5.000',
      'remainingQuantity': '2.500',
      'isArchived': false,
      'createdAt': '2026-08-01T00:00:00.000Z',
    },
  ],
};

void main() {
  test('maps a page of models to entities, preserving order', () async {
    final repository = ProductRepositoryImpl(
      productApi: _FakeProductApi(
        page: PagedProductsModel.fromJson({
          'items': [productJson(), productJson(id: 'p2')],
          'hasMore': true,
        }),
      ),
    );

    final result = await repository.getProducts(filter: const ProductFilter(), page: 1);

    expect(result.items.map((p) => p.id), ['p1', 'p2']);
    expect(result.hasMore, isTrue);
    expect(result.items.first.batches.single.unitPrice, Decimal.parse('12.75'));
  });

  test('forwards the filter as query parameters alongside paging', () async {
    final api = _FakeProductApi(
      page: PagedProductsModel.fromJson({'items': const [], 'hasMore': false}),
    );
    final repository = ProductRepositoryImpl(productApi: api);

    await repository.getProducts(
      filter: const ProductFilter(
        query: 'oil',
        quickFilter: ProductQuickFilter.expiringSoon,
      ),
      page: 3,
      limit: 50,
    );

    expect(api.lastFilter?['search'], 'oil');
    expect(api.lastFilter?['status'], 'expiringSoon');
    expect(api.lastPage, 3);
    expect(api.lastLimit, 50);
  });

  test('returns null when a barcode lookup is not found', () async {
    final repository = ProductRepositoryImpl(
      productApi: _FakeProductApi(error: const NotFoundException(message: 'nope')),
    );

    expect(await repository.findByBarcode('123'), isNull);
  });

  test('returns the product when a barcode lookup hits', () async {
    final repository = ProductRepositoryImpl(
      productApi: _FakeProductApi(product: ProductModel.fromJson(productJson())),
    );

    expect((await repository.findByBarcode('123'))?.id, 'p1');
  });

  test('lets non-404 errors propagate from a barcode lookup', () async {
    final repository = ProductRepositoryImpl(
      productApi: _FakeProductApi(error: const NetworkException(message: 'offline')),
    );

    expect(() => repository.findByBarcode('123'), throwsA(isA<NetworkException>()));
  });

  test('sends allocations in the order the allocator resolved them', () async {
    final api = _FakeProductApi(product: ProductModel.fromJson(productJson()));
    final repository = ProductRepositoryImpl(productApi: api);

    await repository.consume('p1', [
      BatchAllocation(batchId: 'b1', quantity: Decimal.parse('1.5')),
      BatchAllocation(batchId: 'b2', quantity: Decimal.parse('0.5')),
    ]);

    final sent = api.lastConsume!.toJson()['allocations'] as List<dynamic>;
    expect((sent.first as Map)['batchId'], 'b1');
    expect((sent.first as Map)['quantity'], '1.5');
  });

  test('lets data-layer exceptions propagate untouched', () async {
    final repository = ProductRepositoryImpl(
      productApi: _FakeProductApi(error: const NetworkException(message: 'offline')),
    );

    expect(
      () => repository.getProducts(filter: const ProductFilter(), page: 1),
      throwsA(isA<NetworkException>()),
    );
  });
}

class _FakeProductApi implements ProductApi {
  _FakeProductApi({this.page, this.product, this.error});

  final PagedProductsModel? page;
  final ProductModel? product;
  final Object? error;

  Map<String, dynamic>? lastFilter;
  int? lastPage;
  int? lastLimit;
  ConsumeRequest? lastConsume;

  BaseResponse<T> _envelope<T>(T value) => BaseResponse<T>(code: 'OK', data: value);

  @override
  Future<BaseResponse<PagedProductsModel>> getProducts(
    Map<String, dynamic> filter, {
    required int page,
    required int limit,
  }) async {
    lastFilter = filter;
    lastPage = page;
    lastLimit = limit;
    if (error != null) throw error!;
    return _envelope(this.page!);
  }

  @override
  Future<BaseResponse<ProductModel>> getProductByBarcode(String barcode) async {
    if (error != null) throw error!;
    return _envelope(product!);
  }

  @override
  Future<BaseResponse<ProductModel>> consume(String id, ConsumeRequest body) async {
    lastConsume = body;
    if (error != null) throw error!;
    return _envelope(product!);
  }

  @override
  Future<BaseResponse<ProductModel>> getProduct(String id) => throw UnimplementedError();

  @override
  Future<BaseResponse<List<String>>> getCategories() => throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> createProduct(ProductRequest body) =>
      throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> updateProduct(String id, ProductRequest body) =>
      throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> archiveProduct(String id) => throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> restoreProduct(String id) => throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> addBatch(String id, BatchRequest body) =>
      throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> updateBatch(
    String id,
    String batchId,
    BatchRequest body,
  ) => throw UnimplementedError();

  @override
  Future<BaseResponse<ProductModel>> archiveBatch(String id, String batchId) =>
      throw UnimplementedError();
}
