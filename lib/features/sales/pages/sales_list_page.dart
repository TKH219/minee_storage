import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

class SalesListPage extends StatelessWidget {
  const SalesListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: Text(LocaleKeys.sales_title.tr())),
      body: EmptyView(
        icon: Icons.receipt_long_outlined,
        title: LocaleKeys.sales_emptyTitle.tr(),
        subtitle: LocaleKeys.sales_emptySubtitle.tr(),
      ),
    );
  }
}
