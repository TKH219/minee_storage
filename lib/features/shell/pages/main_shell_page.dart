import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';
import 'package:mine_storage/features/products/states/product_list_state.dart';
import 'package:mine_storage/features/products/widgets/add_product_sheet.dart';

import '../widgets/app_nav_bar.dart';

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
        onNewSale: () => _openAddSheet(context, ref),
      ),
    );
  }

  /// Re-tapping the active tab pops that branch back to its root.
  void _goBranch(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

  /// The design's only route into adding stock. It lives here rather than as a
  /// floating button on the list because the shell sets `extendBody`, which puts
  /// anything the list floats behind this very bar.
  Future<void> _openAddSheet(BuildContext context, WidgetRef ref) async {
    final choice = await showAddProductSheet(context);
    if (choice == null || !context.mounted) return;

    switch (choice) {
      case AddProductRoute.scan:
        await context.pushNamed<void>(AppRoutes.productScanName);
      case AddProductRoute.manual:
        await context.pushNamed<String>(AppRoutes.productNewName);
    }

    // The list is behind this sheet, already loaded, and has no idea a product
    // was just created — without this it keeps showing the empty state over a
    // catalogue that is no longer empty.
    if (context.mounted) {
      await ref.read(productListStateProvider.notifier).refresh();
    }
  }
}
