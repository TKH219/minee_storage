import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'nav_metrics.dart';

/// An action, never a destination — it opens a sheet and never takes a
/// selected state.
class NewSaleAction extends StatelessWidget {
  const NewSaleAction({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.translate(
          offset: const Offset(0, -NavMetrics.actionLift),
          child: GestureDetector(
            onTap: onTap,
            child: Container(
              key: const Key('new-sale-circle'),
              width: NavMetrics.actionSize,
              height: NavMetrics.actionSize,
              decoration: BoxDecoration(
                color: colors.fillPrimary,
                shape: BoxShape.circle,
                border: Border.all(
                  color: colors.barSurface,
                  width: NavMetrics.actionRingWidth,
                ),
                boxShadow: colors.elevation,
              ),
              child: Icon(
                Icons.add_rounded,
                size: NavMetrics.actionIconSize,
                color: colors.onPrimary,
              ),
            ),
          ),
        ),
        Transform.translate(
          offset: const Offset(0, -NavMetrics.actionLift + NavMetrics.itemGap),
          child: Text(
            LocaleKeys.shell_newSale.tr(),
            style: context.textStyles.sansCaption.copyWith(
              fontSize: NavMetrics.labelSize,
              height: NavMetrics.labelHeight,
              letterSpacing: NavMetrics.labelTracking,
              color: colors.neutral6,
            ),
          ),
        ),
      ],
    );
  }
}
