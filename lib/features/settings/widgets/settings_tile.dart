import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'settings_metrics.dart';

/// One row of the settings list: icon, label, current value, chevron.
class SettingsTile extends StatelessWidget {
  const SettingsTile({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  /// The mono figure on the right. Absent on rows that only lead somewhere.
  final String? value;

  /// Replaces the value and the chevron — the switch row uses this.
  final Widget? trailing;

  /// The way out is drawn apart from everything else.
  final bool destructive;

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
              Icon(
                icon,
                size: SettingsMetrics.iconSize,
                color: destructive ? colors.red5 : colors.neutral7,
              ),
              const SizedBox(width: SettingsMetrics.tileGap),
              Expanded(
                child: Text(
                  label,
                  key: Key('settings-label-$label'),
                  // The design's `.lbl { flex:1; min-width:0 }` — the label
                  // shrinks and clips rather than wrapping, which would
                  // otherwise push the row past its 56px height in Vietnamese.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: SettingsMetrics.labelSize,
                    fontWeight: destructive ? FontWeight.w500 : null,
                    color: destructive ? colors.red5 : null,
                  ),
                ),
              ),
              if (trailing != null)
                trailing!
              else ...[
                if (value != null)
                  Text(
                    value!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.textStyles.monoBody.copyWith(
                      fontSize: SettingsMetrics.valueSize,
                      color: colors.neutral6,
                    ),
                  ),
                // The destructive row leads nowhere further — it acts here.
                if (!destructive) ...[
                  const SizedBox(width: SettingsMetrics.tileGap),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: SettingsMetrics.chevronSize,
                    color: colors.neutral4,
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
