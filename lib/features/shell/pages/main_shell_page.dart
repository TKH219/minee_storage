import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:mine_storage/features/shell/widgets/add_action_button.dart';
import 'package:mine_storage/features/shell/widgets/floating_nav_bar.dart';
import 'package:mine_storage/shared/ui/coming_soon_snack.dart';
import 'package:mine_storage/shared/ui/nav_metrics.dart';

class MainShellPage extends StatelessWidget {
  const MainShellPage({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Back from a secondary tab returns to Home rather than leaving the app,
    // which is what users expect from a tabbed Android app.
    return PopScope(
      canPop: navigationShell.currentIndex == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          navigationShell.goBranch(0);
        }
      },
      child: Scaffold(
        extendBody: true,
        body: Stack(
          children: [
            navigationShell,
            Positioned(
              left: kNavBarHorizontalInset,
              right: kNavBarHorizontalInset,
              bottom: MediaQuery.paddingOf(context).bottom + kNavBarBottomGap,
              child: Row(
                children: [
                  Expanded(
                    child: FloatingNavBar(
                      currentIndex: navigationShell.currentIndex,
                      onDestinationSelected: _goToBranch,
                    ),
                  ),
                  const SizedBox(width: kNavBarButtonGap),
                  AddActionButton(
                    onPressed: () =>
                        showComingSoonSnack(context, 'Adding items'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Re-tapping the active tab pops that branch back to its root instead of
  /// doing nothing.
  void _goToBranch(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}
