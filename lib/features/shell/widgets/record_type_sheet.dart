import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/features/sales/list/widgets/ledger_labels.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

/// The centre button is an action, never a tab. It opens the four transaction
/// types in the order they occur — sales daily, deliveries weekly, write-offs
/// and counts rarely — so the choice is made before any form loads.
Future<TransactionType?> showRecordTypeSheet(BuildContext context) {
  return showModalBottomSheet<TransactionType>(
    context: context,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Text(
              LocaleKeys.sales_recordTitle.tr(),
              style: sheetContext.textStyles.sansTitleHeading3,
            ),
          ),
          for (final type in TransactionType.values)
            _RecordRow(
              type: type,
              onTap: () => Navigator.of(sheetContext).pop(type),
            ),
          const SizedBox(height: 12),
        ],
      ),
    ),
  );
}

class _RecordRow extends StatelessWidget {
  const _RecordRow({required this.type, required this.onTap});

  final TransactionType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final styles = context.textStyles;
    final (title, body) = switch (type) {
      TransactionType.sale => (
        LocaleKeys.sales_recordSale.tr(),
        LocaleKeys.sales_recordSaleBody.tr(),
      ),
      TransactionType.receive => (
        LocaleKeys.sales_recordReceive.tr(),
        LocaleKeys.sales_recordReceiveBody.tr(),
      ),
      TransactionType.writeOff => (
        LocaleKeys.sales_recordWriteOff.tr(),
        LocaleKeys.sales_recordWriteOffBody.tr(),
      ),
      TransactionType.adjust => (
        LocaleKeys.sales_recordCount.tr(),
        LocaleKeys.sales_recordCountBody.tr(),
      ),
    };

    return InkWell(
      key: Key('record-type-${type.name}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: colors.neutral2,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                transactionTypeIcon(type),
                size: 20,
                color: colors.neutral7,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: styles.sansBodyBold.copyWith(color: colors.neutral9),
                  ),
                  Text(
                    body,
                    style: styles.sansCaption.copyWith(color: colors.neutral6),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.neutral4),
          ],
        ),
      ),
    );
  }
}
