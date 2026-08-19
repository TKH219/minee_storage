import 'package:flutter/material.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'lottie_animation.dart';

/// Past a second, silence reads as broken — so say what is happening.
class LabelledSpinner extends StatelessWidget {
  const LabelledSpinner({super.key, required this.label, this.size = 40});

  final String label;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LottieAnimation(name: 'spinner', size: size),
        const SizedBox(height: 12),
        Text(
          label,
          textAlign: TextAlign.center,
          style: context.textStyles.sansBody.copyWith(color: context.colors.neutral6),
        ),
      ],
    );
  }
}
