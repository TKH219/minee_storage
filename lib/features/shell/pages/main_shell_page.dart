import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/app/router/app_routes.dart';

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
        onNewSale: () => context.pushNamed(AppRoutes.saleNewName),
      ),
    );
  }

  /// Re-tapping the active tab pops that branch back to its root.
  void _goBranch(int index) => navigationShell.goBranch(
        index,
        initialLocation: index == navigationShell.currentIndex,
      );

}
