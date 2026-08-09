import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';
import 'package:mine_storage/shared/ui/nav_metrics.dart';

class AddActionButton extends StatelessWidget {
  const AddActionButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Semantics(
      button: true,
      label: 'Add',
      child: Material(
        color: colors.primary4,
        shape: const CircleBorder(),
        elevation: 8,
        shadowColor: colors.black.withValues(alpha: 0.20),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          child: SizedBox(
            width: kNavBarHeight,
            height: kNavBarHeight,
            child: Icon(
              Icons.add_rounded,
              size: 30,
              color: colors.isDark ? colors.neutral0 : colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
