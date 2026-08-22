import 'package:mine_storage/data/models/models.dart';

abstract class StoreDataSource {
  Future<List<StoreModel>> fetchMine(String ownerId);

  Future<List<StoreCategoryModel>> fetchCategories();

  Future<List<CurrencyModel>> fetchCurrencies();

  Future<StoreModel> insertStore(CreateStoreRequest request);

  String? get currentUserId;
}
