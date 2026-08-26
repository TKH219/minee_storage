import 'package:flutter/widgets.dart';

/// Measured from the design's S19 basket (`#sale`, node `3321:11591`).
abstract class CartMetrics {
  static const EdgeInsets linePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 13);
  static const double lineGap = 12;
  static const double thumbSize = 44;
  static const double thumbRadius = 10;
  static const double nameSize = 15;
  static const double amountSize = 14;
  static const double metaSize = 12;
  static const double lineInnerGap = 3;

  static const double splitTopGap = 2;
  static const double splitGap = 6;
  static const double splitSize = 11.5;
  static const double splitIconSize = 14;

  static const EdgeInsets addLinePadding = EdgeInsets.fromLTRB(16, 12, 16, 0);
  static const double moneyTopGap = 12;
  static const EdgeInsets payPadding = EdgeInsets.fromLTRB(16, 14, 16, 20);
}
