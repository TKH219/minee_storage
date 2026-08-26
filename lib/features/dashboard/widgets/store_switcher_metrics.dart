import 'package:flutter/widgets.dart';

/// Measured from the design's S07 sheet (`#dashboard`, node `3321:11359`).
abstract class StoreSwitcherMetrics {
  static const double sheetRadius = 20;
  static const EdgeInsets sheetPadding = EdgeInsets.only(top: 10, bottom: 24);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double blockGap = 16;

  static const double grabWidth = 36;
  static const double grabHeight = 4;
  static const double grabBottomGap = 2;

  static const double titleSize = 18;

  static const double tileMinHeight = 56;
  static const EdgeInsets tilePadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const double tileGap = 14;
  static const double labelSize = 15;
  static const double valueSize = 13;
  static const double dividerGap = 8;

  static const double radioSize = 20;
  static const double radioBorder = 2;
  static const double radioSelectedBorder = 6;

  static const double badgeHeight = 22;
  static const double badgeRadius = 999;
  static const EdgeInsets badgePadding = EdgeInsets.symmetric(horizontal: 9);
  static const double badgeTextSize = 11;

  static const EdgeInsets noticePadding = EdgeInsets.symmetric(horizontal: 13, vertical: 12);
  static const double noticeRadius = 10;
  static const double noticeGap = 10;
  static const double noticeTextSize = 13;
  static const double noticeTextHeight = 1.45;
  static const double noticeIconSize = 20;
}
