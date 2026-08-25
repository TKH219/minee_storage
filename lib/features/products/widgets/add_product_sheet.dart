import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

enum AddProductRoute { scan, manual }

/// The two ways a product gets into the catalogue. Scanning is offered first
/// because it is the faster one and fills the barcode in either branch.
Future<AddProductRoute?> showAddProductSheet(BuildContext context) {
  return showModalBottomSheet<AddProductRoute>(
    context: context,
    backgroundColor: context.colors.neutral0,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (sheetContext) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: sheetContext.colors.neutral3,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                LocaleKeys.products_addTitle.tr(),
                style: sheetContext.textStyles.sansTitleHeading3,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ListTile(
            key: const Key('add-scan-tile'),
            leading: const Icon(Icons.qr_code_scanner_rounded),
            title: Text(LocaleKeys.products_scanBarcode.tr()),
            onTap: () => Navigator.of(sheetContext).pop(AddProductRoute.scan),
          ),
          ListTile(
            key: const Key('add-manual-tile'),
            leading: const Icon(Icons.edit_outlined),
            title: Text(LocaleKeys.products_addManually.tr()),
            onTap: () => Navigator.of(sheetContext).pop(AddProductRoute.manual),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
}
