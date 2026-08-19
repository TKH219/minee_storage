import 'package:mine_storage/data/mock/mock_database.dart' show Allocation;
import 'package:mine_storage/domain/entities/lot.dart';
import 'package:mine_storage/domain/entities/product.dart';

abstract class ProductRepository {
  Future<List<Product>> list({
    required String storeId,
    bool includeArchived = false,
    String? query,
  });

  Future<Product> byId(String id);

  Future<List<Allocation>> previewConsumption(String productId, double quantity);

  Future<void> consume(String productId, double quantity);

  Future<void> addLot(Lot lot);

  Future<void> archive(String id);

  Future<void> restore(String id);
}
