import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// The tonal button — a quieter affirmative that still reads as primary.
/// Filled and text buttons come from `theme.dart`'s button themes unchanged.
class AppTonalButton extends StatelessWidget {
  const AppTonalButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: colors.fillPrimary,
        foregroundColor: colors.onPrimary,
      ),
      child: Text(label),
    );
  }
}

class AppDestructiveButton extends StatelessWidget {
  const AppDestructiveButton({super.key, required this.label, this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Text(
        label,
        style: context.textStyles.sansBodyBold.copyWith(color: context.colors.red5),
      ),
    );
  }
}
