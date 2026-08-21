import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';

Store storeFixture({
  String id = 's-1',
  String ownerId = 'uid-1',
  String name = 'Tạp hóa Linh',
  String categoryCode = 'grocery',
  String currencyCode = 'VND',
}) => Store(
  id: id,
  ownerId: ownerId,
  name: name,
  categoryCode: categoryCode,
  currencyCode: currencyCode,
);

class FakeStoreRepository implements StoreRepository {
  FakeStoreRepository({
    this.stores = const [],
    this.created,
    this.categoryList = const [],
    this.error,
  });

  List<Store> stores;
  Store? created;
  List<StoreCategory> categoryList;
  Object? error;

  final List<String> calls = [];

  void _maybeThrow() {
    if (error != null) throw error!;
  }

  @override
  Future<List<Store>> listMine() async {
    calls.add('listMine');
    _maybeThrow();
    return stores;
  }

  @override
  Future<Store> create({
    required String name,
    required String categoryCode,
    required String currencyCode,
    String? address,
    String? url,
    String? logoUrl,
  }) async {
    calls.add('create:$name:$categoryCode:$currencyCode');
    _maybeThrow();
    final store = created ?? storeFixture(name: name, categoryCode: categoryCode);
    stores = [...stores, store];
    return store;
  }

  @override
  Future<List<StoreCategory>> categories() async {
    calls.add('categories');
    _maybeThrow();
    return categoryList;
  }
}
