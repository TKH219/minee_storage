import 'package:mine_storage/domain/entities/store.dart';

abstract class StoreRepository {
  Future<List<Store>> list();
}
