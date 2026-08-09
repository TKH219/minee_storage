import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/features/shell/widgets/nav_bar_item.dart';
import 'package:mine_storage/shared/ui/nav_metrics.dart';

/// Tab order matches the shell branch order in `buildAppShellRoute()`.
const List<NavBarDestination> kNavBarDestinations = [
  NavBarDestination(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Home',
  ),
  NavBarDestination(
    icon: Icons.flag_outlined,
    selectedIcon: Icons.flag_rounded,
    label: 'Report',
  ),
  NavBarDestination(
    icon: Icons.settings_outlined,
    selectedIcon: Icons.settings_rounded,
    label: 'Settings',
  ),
];

class FloatingNavBar extends StatelessWidget {
  const FloatingNavBar({
    super.key,
    required this.currentIndex,
    required this.onDestinationSelected,
  });

  final int currentIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // neutral0 is *darker* than the neutral1 scaffold in the dark ramp, which
    // makes the bar sink rather than float; neutral2 restores the lift.
    final surface = colors.isDark ? colors.neutral2 : colors.neutral0;

    return Material(
      color: surface,
      elevation: 8,
      shadowColor: colors.black.withValues(alpha: 0.20),
      borderRadius: BorderRadius.circular(kNavBarHeight / 2),
      clipBehavior: Clip.antiAlias,
      child: SizedBox(
        height: kNavBarHeight,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Row(
            children: [
              for (var index = 0; index < kNavBarDestinations.length; index++)
                Expanded(
                  child: NavBarItem(
                    destination: kNavBarDestinations[index],
                    isSelected: index == currentIndex,
                    onTap: () => onDestinationSelected(index),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
