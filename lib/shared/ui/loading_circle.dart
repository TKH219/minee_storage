import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

/// Full-bleed blocking loader used by [BaseViewState]'s shared overlay.
class LoadingCircle extends StatelessWidget {
  const LoadingCircle({super.key, this.dimBackground = true});

  final bool dimBackground;

  @override
  Widget build(BuildContext context) {
    return AbsorbPointer(
      child: ColoredBox(
        color: dimBackground
            ? context.colors.black.withValues(alpha: 0.25)
            : Colors.transparent,
        child: Center(
          child: SizedBox.square(
            dimension: 36,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: context.colors.primary4,
            ),
          ),
        ),
      ),
    );
  }
}
