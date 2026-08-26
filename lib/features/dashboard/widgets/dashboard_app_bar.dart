import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'dashboard_metrics.dart';

/// S08's app bar: the store you are looking at on the left, settings on the
/// right. Settings is reached from here rather than from a tab.
class DashboardAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DashboardAppBar({
    super.key,
    required this.storeName,
    required this.onSwitchStore,
    required this.onOpenSettings,
  });

  final String storeName;
  final VoidCallback onSwitchStore;
  final VoidCallback onOpenSettings;

  @override
  Size get preferredSize => const Size.fromHeight(DashboardMetrics.appBarHeight);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Material(
      color: colors.neutral0,
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: DashboardMetrics.appBarHeight,
          child: Padding(
            padding: DashboardMetrics.appBarPadding,
            child: Row(
              children: [
                Flexible(child: _StoreChip(name: storeName, onTap: onSwitchStore)),
                const SizedBox(width: DashboardMetrics.appBarGap),
                const Spacer(),
                IconButton(
                  key: const Key('dashboard-settings-button'),
                  onPressed: onOpenSettings,
                  tooltip: LocaleKeys.dashboard_settings.tr(),
                  iconSize: DashboardMetrics.iconSize,
                  constraints: const BoxConstraints.tightFor(
                    width: DashboardMetrics.iconButtonSize,
                    height: DashboardMetrics.iconButtonSize,
                  ),
                  padding: EdgeInsets.zero,
                  icon: Icon(Icons.settings_outlined, color: colors.neutral7),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StoreChip extends StatelessWidget {
  const _StoreChip({required this.name, required this.onTap});

  final String name;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      key: const Key('dashboard-store-chip'),
      onTap: onTap,
      borderRadius: BorderRadius.circular(DashboardMetrics.storeChipRadius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Flexible(
            child: Container(
              padding: DashboardMetrics.storeChipPadding,
              decoration: BoxDecoration(
                color: colors.neutral1,
                border: Border.all(color: colors.neutral2),
                borderRadius: BorderRadius.circular(
                  DashboardMetrics.storeChipRadius,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: DashboardMetrics.storeChipDot,
                    height: DashboardMetrics.storeChipDot,
                    decoration: BoxDecoration(
                      color: colors.inkPrimary,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: DashboardMetrics.storeChipGap),
                  Flexible(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: context.textStyles.sansBodyBold.copyWith(
                        fontSize: DashboardMetrics.storeChipTextSize,
                        color: colors.neutral8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: DashboardMetrics.chevronSize,
            color: colors.neutral7,
          ),
        ],
      ),
    );
  }
}
