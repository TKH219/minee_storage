import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

class AppFilterChip extends StatelessWidget {
  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    this.showDot = false,
    this.onTap,
  });

  final String label;
  final bool selected;
  final bool showDot;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: selected ? colors.highlight : colors.neutral0,
            borderRadius: BorderRadius.circular(17),
            border: Border.all(color: selected ? colors.primary2 : colors.neutral3),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showDot) ...[
                  Container(
                    key: const Key('chip-dot'),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: colors.orange5,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  label,
                  style: context.textStyles.sansBody.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: selected ? colors.primary5 : colors.neutral7,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
