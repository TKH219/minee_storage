import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'nav_metrics.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class NavBarItem extends StatelessWidget {
  const NavBarItem({
    super.key,
    required this.destination,
    required this.selected,
    required this.onTap,
  });

  final NavDestination destination;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final content = selected ? colors.inkPrimary : colors.neutral6;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: NavMetrics.itemMinHeight),
        child: Padding(
          padding: const EdgeInsets.only(top: NavMetrics.itemTopPadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(destination.icon, size: NavMetrics.iconSize, color: content),
              const SizedBox(height: NavMetrics.itemGap),
              Text(
                destination.label,
                style: context.textStyles.sansCaption.copyWith(
                  fontSize: NavMetrics.labelSize,
                  height: NavMetrics.labelHeight,
                  letterSpacing: NavMetrics.labelTracking,
                  color: content,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
