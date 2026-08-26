import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'sale_metrics.dart';

/// The design's `.btn.pri` — the affirmative that carries the flow forward.
class SalePrimaryButton extends StatelessWidget {
  const SalePrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.padding,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.fillPrimary,
        foregroundColor: colors.onPrimary,
        disabledBackgroundColor: colors.neutral3,
        disabledForegroundColor: colors.neutral5,
        padding: padding,
        minimumSize: const Size.fromHeight(SaleMetrics.buttonHeight),
        textStyle: context.textStyles.sansBodyBold.copyWith(
          fontSize: SaleMetrics.buttonTextSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(SaleMetrics.buttonRadius),
        ),
      ),
      child: _Label(label: label, icon: icon),
    );
  }
}

/// The design's `.btn.sec` — an outlined alternative that does not compete.
class SaleSecondaryButton extends StatelessWidget {
  const SaleSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.padding,
    this.small = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final EdgeInsets? padding;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: colors.neutral9,
        side: BorderSide(
          color: colors.neutral3,
          width: SaleMetrics.secondaryBorderWidth,
        ),
        padding: padding,
        minimumSize: Size.fromHeight(
          small ? SaleMetrics.smallButtonHeight : SaleMetrics.buttonHeight,
        ),
        textStyle: context.textStyles.sansBodyBold.copyWith(
          fontSize: small
              ? SaleMetrics.smallButtonTextSize
              : SaleMetrics.buttonTextSize,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(
            small ? SaleMetrics.smallButtonRadius : SaleMetrics.buttonRadius,
          ),
        ),
      ),
      child: _Label(label: label, icon: icon),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    if (icon == null) return Text(label);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: SaleMetrics.buttonIconSize),
        const SizedBox(width: SaleMetrics.buttonGap),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
      ],
    );
  }
}
