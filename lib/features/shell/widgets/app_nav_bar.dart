import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'nav_bar_item.dart';
import 'nav_metrics.dart';
import 'new_sale_action.dart';

export 'nav_bar_item.dart' show NavDestination;

class AppNavBar extends StatelessWidget {
  const AppNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onNewSale,
    required this.destinations,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onNewSale;
  final List<NavDestination> destinations;

  static const List<NavDestination> defaultDestinations = [
    NavDestination(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    NavDestination(icon: Icons.inventory_2_outlined, label: 'Products'),
    NavDestination(icon: Icons.receipt_long_outlined, label: 'Sales'),
    NavDestination(icon: Icons.bar_chart_rounded, label: 'Reports'),
  ];

  static const List<NavDestination> staffDestinations = [
    NavDestination(icon: Icons.grid_view_rounded, label: 'Dashboard'),
    NavDestination(icon: Icons.inventory_2_outlined, label: 'Products'),
    NavDestination(icon: Icons.receipt_long_outlined, label: 'Sales'),
    NavDestination(icon: Icons.settings_outlined, label: 'Settings'),
  ];

  /// The action occupies the middle slot, so branch indices 2 and 3 sit to its
  /// right.
  static const int _actionSlot = 2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return SizedBox(
      height: NavMetrics.barHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.barSurface,
          // The hairline darkens a step in dark mode; at neutral2 it disappears
          // against the bar surface.
          border: Border(
            top: BorderSide(color: colors.isDark ? colors.neutral3 : colors.neutral2),
          ),
        ),
        child: Padding(
          padding: NavMetrics.barPadding,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var slot = 0; slot < destinations.length + 1; slot++)
                Expanded(
                  child: slot == _actionSlot
                      ? Center(child: NewSaleAction(onTap: onNewSale))
                      : Center(
                          child: NavBarItem(
                            destination: destinations[_branchFor(slot)],
                            selected: currentIndex == _branchFor(slot),
                            onTap: () => onTap(_branchFor(slot)),
                          ),
                        ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  int _branchFor(int slot) => slot < _actionSlot ? slot : slot - 1;
}
