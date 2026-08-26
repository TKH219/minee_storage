import 'package:flutter/widgets.dart';

/// Measured from the design's S20 picker (`#sale`, node `3321:11591`).
abstract class ProductPickerMetrics {
  static const double sheetHeightFactor = 0.82;
  static const double sheetRadius = 20;
  static const EdgeInsets sheetPadding = EdgeInsets.only(top: 10, bottom: 24);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double blockGap = 16;

  static const double grabWidth = 36;
  static const double grabHeight = 4;
  static const double grabBottomGap = 2;

  static const double searchHeight = 44;
  static const double searchRadius = 12;
  static const EdgeInsets searchPadding = EdgeInsets.symmetric(horizontal: 12);
  static const double searchGap = 9;
  static const double searchTextSize = 15;
  static const double searchRowGap = 10;

  static const double scanButtonSize = 44;
  static const double scanButtonRadius = 12;

  static const EdgeInsets headPadding = EdgeInsets.fromLTRB(16, 10, 16, 6);
  static const double headTextSize = 11;
  static const double headSpacing = 0.08 * headTextSize;

  static const EdgeInsets rowPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 12);
  static const double rowGap = 12;
  static const double thumbSize = 56;
  static const double thumbRadius = 10;
  static const double nameSize = 15;
  static const double priceSize = 13;
  static const double quantitySize = 13;
  static const double rowInnerGap = 3;
  static const double rowBottomGap = 2;

  /// The design's `.row-out` — visible, so the seller still learns the product
  /// exists, but plainly unavailable.
  static const double outOfStockOpacity = 0.6;

  static const double badgeHeight = 22;
  static const double badgeRadius = 999;
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: 9);
  static const double badgeTextSize = 11;
}
