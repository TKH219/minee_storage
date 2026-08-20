import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'settings_metrics.dart';

/// One row of the settings list: icon, label, current value, chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: SettingsMetrics.tileMinHeight),
        child: Padding(
          padding: SettingsMetrics.tilePadding,
          child: Row(
            children: [
              Icon(icon, size: SettingsMetrics.iconSize, color: colors.neutral7),
              const SizedBox(width: SettingsMetrics.tileGap),
              Expanded(
                child: Text(
                  label,
                  // The design's `.lbl { flex:1; min-width:0 }` — the label
                  // shrinks and clips rather than wrapping, which would
                  // otherwise push the row past its 56px height in Vietnamese.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: SettingsMetrics.labelSize,
                  ),
                ),
              ),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.textStyles.monoBody.copyWith(
                  fontSize: SettingsMetrics.valueSize,
                  color: colors.neutral6,
                ),
              ),
              const SizedBox(width: SettingsMetrics.tileGap),
              Icon(
                Icons.chevron_right_rounded,
                size: SettingsMetrics.chevronSize,
                color: colors.neutral4,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
