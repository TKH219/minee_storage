import 'package:flutter/material.dart';

import 'lottie_animation.dart';

/// Bounded, in-place waits: a submitting button, a next page arriving. The
/// label stays and the target keeps its size, so the row never jumps.
class ButtonDots extends StatelessWidget {
  const ButtonDots({super.key, this.size = 22});

  final double size;

  @override
  Widget build(BuildContext context) =>
      LottieAnimation(name: 'dots', size: size);
}
