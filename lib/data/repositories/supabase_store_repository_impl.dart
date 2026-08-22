import 'package:mine_storage/app/extensions/string_extensions.dart';
import 'package:mine_storage/core/exceptions/exceptions.dart';
import 'package:mine_storage/data/data_sources/remote/store_data_source.dart';
import 'package:mine_storage/data/models/models.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/domain/repositories/store_repository.dart';

class SupabaseStoreRepositoryImpl implements StoreRepository {
  SupabaseStoreRepositoryImpl(this._dataSource);

  final StoreDataSource _dataSource;

  @override
  Future<List<Store>> listMine() {
    return _guard(() async {
      final ownerId = _dataSource.currentUserId;
      if (ownerId == null) return const <Store>[];

      final rows = await _dataSource.fetchMine(ownerId);
      return rows.map(Store.fromRow).toList();
    });
  }

  @override
  Future<Store> create({
    required String name,
    required String categoryCode,
    required String currencyId,
    String? address,
    String? url,
    String? logoUrl,
  }) {
    return _guard(() async {
      final row = await _dataSource.insertStore(
        CreateStoreRequest(
          ownerId: _requireSession(),
          name: name.trim(),
          categoryCode: categoryCode,
          currencyId: currencyId,
          address: _blankToNull(address),
          url: normalisedUrlOrNull(url),
          logoUrl: _blankToNull(logoUrl),
        ),
      );
      return Store.fromRow(row);
    });
  }

  @override
  Future<List<StoreCategory>> categories() {
    return _guard(() async {
      final rows = await _dataSource.fetchCategories();
      final categories = rows.map(StoreCategory.fromRow).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return categories;
    });
  }

  @override
  Future<List<Currency>> currencies() {
    return _guard(() async {
      final rows = await _dataSource.fetchCurrencies();
      final currencies = rows.map(Currency.fromRow).toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
      return currencies;
    });
  }

  String? _blankToNull(String? value) {
    final trimmed = value?.trim() ?? '';
    return trimmed.isEmpty ? null : trimmed;
  }

  String _requireSession() {
    final id = _dataSource.currentUserId;
    if (id == null) {
      throw const UnauthorizedException(
        message: 'Your session has expired. Please sign in again.',
      );
    }
    return id;
  }

  /// These calls go over Dio, so [ErrorInterceptor] has already turned any
  /// failure into a typed [AppException] carried on the DioException. Catching
  /// and re-mapping here would flatten it back to "unknown".
  Future<T> _guard<T>(Future<T> Function() action) => action();
}
