import 'package:flutter/widgets.dart';

/// Measured from the design's S22 fees editor (`#sale`, node `3321:11591`).
abstract class FeeMetrics {
  static const double sheetHeightFactor = 0.76;
  static const double sheetRadius = 20;
  static const EdgeInsets sheetPadding = EdgeInsets.only(top: 10, bottom: 24);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double blockGap = 16;

  static const double grabWidth = 36;
  static const double grabHeight = 4;
  static const double grabBottomGap = 2;
  static const double titleSize = 18;

  static const EdgeInsets rowPadding = EdgeInsets.symmetric(vertical: 11);
  static const double rowGap = 11;
  static const double nameSize = 14;
  static const double baseSize = 11.5;
  static const double amountSize = 14;

  static const double tagTextSize = 10;
  static const double tagSpacing = 0.04 * tagTextSize;
  static const EdgeInsets tagPadding = EdgeInsets.symmetric(horizontal: 6, vertical: 2);
  static const double tagRadius = 4;

  static const EdgeInsets noticePadding = EdgeInsets.symmetric(horizontal: 13, vertical: 12);
  static const double noticeRadius = 10;
  static const double noticeGap = 10;
  static const double noticeTextSize = 13;
  static const double noticeTextHeight = 1.45;
  static const double noticeIconSize = 20;
}
