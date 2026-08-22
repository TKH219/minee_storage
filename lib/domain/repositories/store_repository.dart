import 'package:mine_storage/domain/entities/entities.dart';

abstract class StoreRepository {
  /// Every store the signed-in user owns. Empty when nobody is signed in.
  Future<List<Store>> listMine();

  Future<Store> create({
    required String name,
    required String categoryCode,
    required String currencyId,
    String? address,
    String? url,
    String? logoUrl,
  });

  Future<List<StoreCategory>> categories();

  Future<List<Currency>> currencies();
}
