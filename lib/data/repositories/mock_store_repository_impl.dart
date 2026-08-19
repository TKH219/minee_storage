import 'package:mine_storage/data/mock/mock_database.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';

class MockStoreRepositoryImpl implements StoreRepository {
  MockStoreRepositoryImpl(
    this._db, {
    this.latency = const Duration(milliseconds: 350),
  });

  final MockDatabase _db;
  final Duration latency;

  @override
  Future<List<Store>> list() async {
    await Future<void>.delayed(latency);
    return _db.stores;
  }
}
