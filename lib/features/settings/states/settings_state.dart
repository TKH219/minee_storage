import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/providers.dart';
import 'package:mine_storage/shared/utils/currency_formatter.dart';
import 'package:mine_storage/shared/utils/logger.dart';

final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(
  CurrencyNotifier.new,
);

final currencyFormatterProvider = Provider<CurrencyFormatter>(
  (ref) => CurrencyFormatter(ref.watch(currencyProvider)),
);

/// The currency prices are *displayed* in.
///
/// Only the code is persisted: symbol and precision belong to the `currencies`
/// table, and caching them locally would let a stale copy outlive a correction
/// made there. Until the table answers, [Currency.vnd] stands in — the same
/// default a new shop is created with.
class CurrencyNotifier extends Notifier<Currency> {
  static const String storageKey = 'app_currency_code';

  @override
  Currency build() {
    unawaited(_restore());
    return Currency.vnd;
  }

  Future<void> setCurrency(Currency currency) async {
    if (state.code == currency.code) return;
    state = currency;
    try {
      await ref.read(sharedPreferencesProvider).setString(storageKey, currency.code);
    } on Exception catch (e) {
      logger.e('Failed to persist currency', error: e);
    }
  }

  Future<void> _restore() async {
    final code = ref.read(sharedPreferencesProvider).getString(storageKey);
    if (code == null || code == Currency.vnd.code) return;
    try {
      final currencies = await ref.read(storeRepositoryProvider).currencies();
      for (final currency in currencies) {
        if (currency.code == code) {
          state = currency;
          return;
        }
      }
    } on Object catch (e) {
      // A currency that will not load is a display concern, not a blocker:
      // the VND fallback still renders every price.
      logger.e('Failed to restore currency', error: e);
    }
  }
}
