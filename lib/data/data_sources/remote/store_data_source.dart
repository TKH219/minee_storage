abstract class StoreDataSource {
  Future<List<Map<String, dynamic>>> fetchMine(String ownerId);

  Future<List<Map<String, dynamic>>> fetchCategories();

  Future<Map<String, dynamic>> insertStore(Map<String, dynamic> values);

  String? get currentUserId;
}
