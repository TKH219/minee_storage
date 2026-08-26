import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

String transactionTypeLabel(TransactionType type) => switch (type) {
  TransactionType.sale => LocaleKeys.sales_typeSale.tr(),
  TransactionType.receive => LocaleKeys.sales_typeReceive.tr(),
  TransactionType.writeOff => LocaleKeys.sales_typeWriteOff.tr(),
  TransactionType.adjust => LocaleKeys.sales_typeAdjust.tr(),
};

IconData transactionTypeIcon(TransactionType type) => switch (type) {
  TransactionType.sale => Icons.shopping_bag_outlined,
  TransactionType.receive => Icons.local_shipping_outlined,
  TransactionType.writeOff => Icons.delete_outline_rounded,
  TransactionType.adjust => Icons.fact_check_outlined,
};

String writeOffReasonLabel(WriteOffReason reason) => switch (reason) {
  WriteOffReason.expired => LocaleKeys.sales_reasonExpired.tr(),
  WriteOffReason.damaged => LocaleKeys.sales_reasonDamaged.tr(),
  WriteOffReason.lost => LocaleKeys.sales_reasonLost.tr(),
  WriteOffReason.internalUse => LocaleKeys.sales_reasonInternalUse.tr(),
  WriteOffReason.other => LocaleKeys.sales_reasonOther.tr(),
};

/// The subtitle beside the time. A sale names who bought, a delivery names the
/// supplier, a write-off names its reason, and a stock count names itself.
String transactionSubtitle(Transaction transaction) {
  final counterparty = transaction.counterparty;
  if (counterparty != null && counterparty.isNotEmpty) return counterparty;
  return switch (transaction.type) {
    TransactionType.sale => LocaleKeys.sales_walkIn.tr(),
    TransactionType.receive => transactionTypeLabel(TransactionType.receive),
    TransactionType.writeOff => transaction.reason == null
        ? transactionTypeLabel(TransactionType.writeOff)
        : writeOffReasonLabel(transaction.reason!),
    TransactionType.adjust => transactionTypeLabel(TransactionType.adjust),
  };
}

/// Today and Yesterday are named; anything older shows its date.
String dayHeaderLabel(DateTime day, DateTime today) {
  final start = DateTime(today.year, today.month, today.day);
  final at = DateTime(day.year, day.month, day.day);
  final formatted = DateFormat.MMMd().format(at);
  if (at == start) return '${LocaleKeys.sales_ledgerToday.tr()} · $formatted';
  if (at == start.subtract(const Duration(days: 1))) {
    return '${LocaleKeys.sales_ledgerYesterday.tr()} · $formatted';
  }
  return DateFormat.yMMMd().format(at);
}
