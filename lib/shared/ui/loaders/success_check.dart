import 'package:flutter/material.dart';

import 'lottie_animation.dart';
import 'motion.dart';

/// Held for 900 ms so the write is seen to land, then the surface dismisses
/// itself. [onComplete] still fires under reduced motion — the flow must not
/// stall just because the animation is frozen.
class SuccessCheck extends StatefulWidget {
  const SuccessCheck({super.key, required this.onComplete, this.size = 72});

  final VoidCallback onComplete;
  final double size;

  @override
  State<SuccessCheck> createState() => _SuccessCheckState();
}

class _SuccessCheckState extends State<SuccessCheck> {
  @override
  void initState() {
    super.initState();
    Future<void>.delayed(MotionDurations.check, () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  Widget build(BuildContext context) =>
      LottieAnimation(name: 'check', size: widget.size, repeat: false);
}
