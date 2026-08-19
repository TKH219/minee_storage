import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

import 'package:mine_storage/app/theme/theme.dart';

import 'motion.dart';

/// The four animations are authored in the design document and tinted at
/// runtime from `primary4`, so one file serves light, dark and any rebrand.
class LottieAnimation extends StatelessWidget {
  const LottieAnimation({
    super.key,
    required this.name,
    required this.size,
    this.repeat = true,
    this.onComplete,
  });

  final String name;
  final double size;
  final bool repeat;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final tint = context.colors.primary4;
    final frozen = prefersReducedMotion(context);

    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        'assets/animations/$name.json',
        repeat: repeat && !frozen,
        animate: !frozen,
        delegates: LottieDelegates(
          values: [
            ValueDelegate.colorFilter(
              const ['**'],
              value: ColorFilter.mode(tint, BlendMode.srcATop),
            ),
          ],
        ),
      ),
    );
  }
}
