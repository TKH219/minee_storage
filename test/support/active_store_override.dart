import 'package:mine_storage/features/products/states/active_store_state.dart';

/// Pins the active store for a test without going through SharedPreferences.
///
/// [activeStoreProvider] became a notifier when the store switcher landed, so
/// `overrideWithValue` is no longer available on it. Use it as:
/// `activeStoreProvider.overrideWith(() => FixedActiveStore('store-a'))`.
class FixedActiveStore extends ActiveStoreNotifier {
  FixedActiveStore(this._storeId);

  final String? _storeId;

  @override
  String? build() => _storeId;
}
