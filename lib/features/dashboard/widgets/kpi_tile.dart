import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/domain/entities/entities.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'dashboard_metrics.dart';

/// One dashboard figure: label, mono value, and how it moved since yesterday.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.id,
    required this.label,
    required this.value,
    required this.delta,
    this.valueColor,
    this.child,
  });

  /// Names the tile for tests and for the value's key.
  final String id;
  final String label;
  final String value;
  final KpiDelta? delta;
  final Color? valueColor;

  /// The sparkline on the wide tile. Nothing on the others.
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.textStyles;

    return Container(
      padding: DashboardMetrics.kpiPadding,
      decoration: BoxDecoration(
        color: colors.neutral0,
        border: Border.all(color: colors.neutral2),
        borderRadius: BorderRadius.circular(DashboardMetrics.kpiRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texts.sansCaption.copyWith(
              fontSize: DashboardMetrics.kpiLabelSize,
              fontWeight: FontWeight.w600,
              letterSpacing: DashboardMetrics.kpiLabelSpacing,
              color: colors.neutral6,
            ),
          ),
          const SizedBox(height: DashboardMetrics.kpiInnerGap),
          Text(
            value,
            key: Key('kpi-value-$id'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: texts.monoBody.copyWith(
              fontSize: DashboardMetrics.kpiValueSize,
              fontWeight: FontWeight.w500,
              height: DashboardMetrics.kpiValueHeight,
              color: valueColor ?? colors.neutral9,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
          if (delta != null) ...[
            const SizedBox(height: DashboardMetrics.kpiInnerGap),
            Text(
              _deltaLabel(delta!),
              key: Key('kpi-delta-$id'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: texts.monoBody.copyWith(
                fontSize: DashboardMetrics.kpiDeltaSize,
                color: switch (delta!.direction) {
                  DeltaDirection.up => colors.green5,
                  DeltaDirection.down => colors.red5,
                  DeltaDirection.flat => colors.neutral6,
                },
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
          if (child != null) ...[
            const SizedBox(height: DashboardMetrics.sparkTopGap),
            child!,
          ],
        ],
      ),
    );
  }

  static String _deltaLabel(KpiDelta delta) {
    if (delta.direction == DeltaDirection.flat) {
      return LocaleKeys.dashboard_deltaFlat.tr();
    }
    if (!delta.hasPercent) {
      return delta.direction == DeltaDirection.up
          ? LocaleKeys.dashboard_deltaUpNew.tr()
          : LocaleKeys.dashboard_deltaDownGone.tr();
    }
    final key = delta.direction == DeltaDirection.up
        ? LocaleKeys.dashboard_deltaUp
        : LocaleKeys.dashboard_deltaDown;
    return key.tr(namedArgs: {'percent': delta.percent.toString()});
  }
}
