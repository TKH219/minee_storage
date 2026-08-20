import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/empty_view.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:go_router/go_router.dart';
import 'package:mine_storage/app/router/app_routes.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.neutral1,
      appBar: AppBar(
        title: const Text('Northside · Main'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.goNamed(AppRoutes.settingsName),
          ),
        ],
      ),
      body: EmptyView(
        icon: Icons.inventory_2_outlined,
        title: LocaleKeys.dashboard_emptyTitle.tr(),
        subtitle: LocaleKeys.dashboard_emptySubtitle.tr(),
      ),
    );
  }
}
