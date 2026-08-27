import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:easy_localization/easy_localization.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';
import 'package:mine_storage/shared/ui/app_snack.dart';

import '../widgets/app_nav_bar.dart';
import '../widgets/record_type_sheet.dart';

class MainShellPage extends ConsumerWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      extendBody: true,
      body: navigationShell,
      bottomNavigationBar: AppNavBar(
        currentIndex: navigationShell.currentIndex,
        destinations: AppNavBar.defaultDestinations,
        onTap: _goBranch,
        onNewSale: () => _record(context),
      ),
    );
  }

  /// The other three types are per product — which goods spoiled, which lot was
  /// counted, which product arrived — so they land on the catalogue rather than
  /// opening a form with nothing to fill it against.
  Future<void> _record(BuildContext context) async {
    final type = await showRecordTypeSheet(context);
    if (type == null || !context.mounted) return;

    if (type == TransactionType.sale) {
      await context.pushNamed(AppRoutes.saleNewName);
      return;
    }
    context.goNamed(AppRoutes.productsName);
    showSuccessSnack(LocaleKeys.sales_recordPickProduct.tr());
  }

  /// Re-tapping the active tab pops that branch back to its root.
  void _goBranch(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

}
