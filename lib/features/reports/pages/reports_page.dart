import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(title: Text(LocaleKeys.reports_title.tr())),
      body: EmptyView(
        icon: Icons.bar_chart_rounded,
        title: LocaleKeys.reports_emptyTitle.tr(),
        subtitle: LocaleKeys.reports_emptySubtitle.tr(),
      ),
    );
  }
}
