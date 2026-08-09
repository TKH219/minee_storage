import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/nav_metrics.dart';

/// The bottom margin clears the floating navigation bar, which is drawn in the
/// shell's `Stack` and so is not accounted for by the snack's own positioning.
void showComingSoonSnack(BuildContext context, String feature) {
  final messenger = ScaffoldMessenger.of(context);
  final bottomInset = MediaQuery.paddingOf(context).bottom;

  messenger
    ..clearSnackBars()
    ..showSnackBar(
      SnackBar(
        content: Text(
          '$feature is coming soon',
          style: context.textStyles.sansBody.copyWith(
            color: context.colors.white,
          ),
        ),
        backgroundColor: context.colors.neutral8,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(
          left: kNavBarHorizontalInset,
          right: kNavBarHorizontalInset,
          bottom: bottomInset + kNavBarReservedSpace,
        ),
        duration: const Duration(seconds: 2),
      ),
    );
}
