import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/l10n/locale_keys.g.dart';

import 'dashboard_metrics.dart';

/// S08's empty state.
///
/// Deliberately not [EmptyView]: four other screens depend on that widget's
/// look, and this one has a different anatomy — an 88px circular art tile and
/// two stacked full-width buttons.
class DashboardEmptyView extends StatelessWidget {
  const DashboardEmptyView({
    super.key,
    required this.onAddProduct,
    required this.onScanBarcode,
  });

  final VoidCallback onAddProduct;
  final VoidCallback onScanBarcode;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.textStyles;

    return Padding(
      padding: DashboardMetrics.emptyPadding,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              key: const Key('dashboard-empty-art'),
              width: DashboardMetrics.emptyArtSize,
              height: DashboardMetrics.emptyArtSize,
              margin: const EdgeInsets.only(
                bottom: DashboardMetrics.emptyArtBottomGap,
              ),
              decoration: BoxDecoration(
                color: colors.neutral1,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: DashboardMetrics.emptyArtIconSize,
                color: colors.neutral4,
              ),
            ),
          ),
          const SizedBox(height: DashboardMetrics.emptyGap),
          Text(
            LocaleKeys.dashboard_emptyTitle.tr(),
            textAlign: TextAlign.center,
            style: texts.sansBodyBold.copyWith(
              fontSize: DashboardMetrics.emptyTitleSize,
              color: colors.neutral9,
            ),
          ),
          const SizedBox(height: DashboardMetrics.emptyGap),
          Text(
            LocaleKeys.dashboard_emptySubtitle.tr(),
            textAlign: TextAlign.center,
            style: texts.sansBody.copyWith(
              fontSize: DashboardMetrics.emptyBodySize,
              height: 1.5,
              color: colors.neutral6,
            ),
          ),
          const SizedBox(
            height: DashboardMetrics.emptyGap + DashboardMetrics.emptyPrimaryTopGap,
          ),
          FilledButton(
            key: const Key('dashboard-add-product'),
            onPressed: onAddProduct,
            style: FilledButton.styleFrom(
              backgroundColor: colors.fillPrimary,
              foregroundColor: colors.onPrimary,
              padding: DashboardMetrics.primaryButtonPadding,
              minimumSize: const Size.fromHeight(DashboardMetrics.buttonHeight),
              textStyle: texts.sansBodyBold.copyWith(
                fontSize: DashboardMetrics.buttonTextSize,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardMetrics.buttonRadius),
              ),
            ),
            child: Text(LocaleKeys.dashboard_addProduct.tr()),
          ),
          const SizedBox(height: DashboardMetrics.emptyGap),
          TextButton(
            key: const Key('dashboard-scan-barcode'),
            onPressed: onScanBarcode,
            style: TextButton.styleFrom(
              foregroundColor: colors.primary4,
              minimumSize: const Size.fromHeight(DashboardMetrics.buttonHeight),
              textStyle: texts.sansBodyBold.copyWith(
                fontSize: DashboardMetrics.buttonTextSize,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardMetrics.buttonRadius),
              ),
            ),
            child: Text(LocaleKeys.dashboard_scanBarcode.tr()),
          ),
        ],
      ),
    );
  }
}
