import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'nav_metrics.dart';

class NavDestination {
  const NavDestination({required this.icon, required this.labelKey});

  final IconData icon;

  /// Held as a key rather than a resolved string so the destination lists stay
  /// `const` and every rebuild picks up the current language.
  final String labelKey;
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
                destination.labelKey.tr(),
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
