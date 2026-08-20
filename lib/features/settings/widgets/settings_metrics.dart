import 'package:flutter/widgets.dart';

/// Measured from the design's settings rows (`#settings`, node `3321:15783`).
/// The Language row is a geometric clone of the Theme row beside it, so both
/// read from these same constants.
abstract class SettingsMetrics {
  static const double tileMinHeight = 56;
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const double tileGap = 14;
  static const double iconSize = 24;
  static const double chevronSize = 20;
  static const double labelSize = 15;
  static const double valueSize = 13;
  static const double sectionLabelSize = 13;
  static const double dividerThickness = 1;
  static const EdgeInsets sectionPadding = EdgeInsets.fromLTRB(16, 24, 16, 8);
}
