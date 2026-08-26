import 'package:flutter/widgets.dart';

/// Measured from the design's dashboard frames (`#dashboard`, node
/// `3321:11359`, and the empty state at `3321:11472`).
abstract class DashboardMetrics {
  static const double appBarHeight = 56;
  static const EdgeInsets appBarPadding = EdgeInsets.fromLTRB(16, 0, 8, 0);
  static const double appBarGap = 12;

  static const EdgeInsets storeChipPadding = EdgeInsets.fromLTRB(8, 5, 10, 5);
  static const double storeChipRadius = 999;
  static const double storeChipGap = 6;
  static const double storeChipTextSize = 13;
  static const double storeChipDot = 8;
  static const double chevronSize = 20;
  static const double iconButtonSize = 40;
  static const double iconSize = 24;

  static const EdgeInsets todayPadding = EdgeInsets.fromLTRB(16, 0, 16, 12);
  static const double todaySize = 12;

  static const double emptyArtSize = 88;
  static const double emptyArtIconSize = 38;
  static const double emptyGap = 12;
  static const double emptyArtBottomGap = 4;
  static const EdgeInsets emptyPadding = EdgeInsets.symmetric(horizontal: 40);
  static const double emptyTitleSize = 18;
  static const double emptyBodySize = 14;
  static const double emptyPrimaryTopGap = 8;

  static const double buttonHeight = 52;
  static const double buttonRadius = 12;
  static const double buttonTextSize = 16;
  static const EdgeInsets primaryButtonPadding = EdgeInsets.symmetric(horizontal: 28);

  static const EdgeInsets kpiGridPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double kpiGap = 10;
  static const EdgeInsets kpiPadding = EdgeInsets.symmetric(horizontal: 14, vertical: 13);
  static const double kpiRadius = 12;
  static const double kpiInnerGap = 3;
  static const double kpiLabelSize = 10.5;
  static const double kpiLabelSpacing = 0.07 * kpiLabelSize;
  static const double kpiValueSize = 19;
  static const double kpiValueHeight = 1.35;
  static const double kpiDeltaSize = 11.5;

  static const double sparkHeight = 28;
  static const double sparkTopGap = 4;
  static const double sparkStroke = 2;
  static const double sparkDotRadius = 3;

  static const double sectionLabelSize = 11;
  static const double sectionLabelSpacing = 0.09 * sectionLabelSize;
  static const EdgeInsets sectionPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double sectionBottomGap = 8;

  static const EdgeInsets noticePadding = EdgeInsets.symmetric(horizontal: 13, vertical: 12);
  static const double noticeRadius = 10;
  static const double noticeGap = 10;
  static const double noticeTextSize = 13;
  static const double noticeTextHeight = 1.45;
  static const double noticeIconSize = 20;
  static const double noticeStackGap = 8;
}
