import 'package:flutter/material.dart';

/// Every animation in the app freezes to its poster frame under reduced motion,
/// per the design's motion policy — the screen still has to read complete when
/// nothing moves.
bool prefersReducedMotion(BuildContext context) => MediaQuery.disableAnimationsOf(context);

abstract class MotionDurations {
  static const Duration spinner = Duration(milliseconds: 1500);
  static const Duration dots = Duration(milliseconds: 1200);
  static const Duration check = Duration(milliseconds: 900);
  static const Duration scan = Duration(milliseconds: 1800);
  static const Duration shimmer = Duration(milliseconds: 1500);
}
