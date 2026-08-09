import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/nav_metrics.dart';

class NavBarDestination {
  const NavBarDestination({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class NavBarItem extends StatelessWidget {
  const NavBarItem({
    super.key,
    required this.destination,
    required this.isSelected,
    required this.onTap,
  });

  final NavBarDestination destination;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final foreground = isSelected ? colors.primary5 : colors.neutral6;

    // primary0 is near-black in the dark ramp and would vanish against the
    // bar, so the highlight steps up one stop there.
    final highlight = isSelected
        ? (colors.isDark ? colors.primary1 : colors.primary0)
        : Colors.transparent;

    return Semantics(
      button: true,
      selected: isSelected,
      label: destination.label,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(kNavBarItemHeight / 2),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          height: kNavBarItemHeight,
          decoration: BoxDecoration(
            color: highlight,
            borderRadius: BorderRadius.circular(kNavBarItemHeight / 2),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isSelected ? destination.selectedIcon : destination.icon,
                size: 22,
                color: foreground,
              ),
              const SizedBox(height: 2),
              Text(
                destination.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.sansCaption.copyWith(
                  color: foreground,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
