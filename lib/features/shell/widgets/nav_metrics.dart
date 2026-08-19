import 'package:flutter/widgets.dart';

/// Measured from the design's rendered navigation bar. The dimension chips in
/// the `#nav-anatomy` sheet quote the superseded three-tab nav spec and do not
/// describe what the file actually draws.
abstract class NavMetrics {
  static const double barHeight = 88;
  static const EdgeInsets barPadding = EdgeInsets.symmetric(horizontal: 4);
  static const double itemTopPadding = 9;
  static const double itemGap = 3;
  static const double itemMinHeight = 48;
  static const double iconSize = 24;
  static const double labelSize = 11;
  static const double labelHeight = 1.3;
  static const double labelTracking = 0.11;
  static const double actionSize = 56;
  static const double actionLift = 20;
  static const double actionRingWidth = 3;
  static const double actionIconSize = 26;
}
