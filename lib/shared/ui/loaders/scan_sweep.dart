import 'package:flutter/material.dart';

import 'lottie_animation.dart';

/// The only thing telling the user the camera is actually running. It stops
/// dead the moment a barcode decodes.
class ScanSweep extends StatelessWidget {
  const ScanSweep({super.key, required this.active, this.size = 240});

  final bool active;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!active) return SizedBox(width: size, height: size);
    return LottieAnimation(name: 'scan', size: size);
  }
}
