import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/products/states/active_store_state.dart';
import 'package:mine_storage/features/settings/states/settings_state.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/store_currency_formatter.dart';

/// The currency the **active store** trades in.
///
/// Money is rendered from this, not from the device preference: a ledger that
/// formats a Vietnamese shop's takings in dollars because the phone is set to
/// dollars is wrong, and §5.3's rounding keys on the minor units, so it is a
/// correctness concern and not only a display one.
///
/// The settings row survives as the fallback for a store that predates
/// `stores.currency_id` — retiring it outright would leave such a store with no
/// symbol at all.
final storeCurrencyProvider = FutureProvider<Currency>((ref) async {
  final fallback = ref.watch(currencyProvider);
  final storeId = ref.watch(activeStoreProvider);
  if (storeId == null) return fallback;

  final stores = await ref.watch(storeRepositoryProvider).listMine();
  final store = stores.where((candidate) => candidate.id == storeId).firstOrNull;
  if (store == null) return fallback;

  final currencies = await ref.watch(storeRepositoryProvider).currencies();
  return currencies.where((candidate) => candidate.id == store.currencyId).firstOrNull ??
      fallback;
});

/// The formatter every transaction figure goes through.
final storeCurrencyFormatterProvider = Provider<StoreCurrencyFormatter>((ref) {
  final currency = ref.watch(storeCurrencyProvider).value;
  return StoreCurrencyFormatter.of(currency ?? ref.watch(currencyProvider));
});
