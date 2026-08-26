import 'package:flutter/widgets.dart';

/// Measured from the design's S21 sheets (`#sale`, node `3321:11591`).
abstract class AllocationMetrics {
  static const double sheetRadius = 20;
  static const EdgeInsets sheetPadding = EdgeInsets.only(top: 10, bottom: 24);
  static const EdgeInsets horizontalPadding = EdgeInsets.symmetric(horizontal: 16);
  static const double blockGap = 16;
  static const double innerGap = 8;

  static const double grabWidth = 36;
  static const double grabHeight = 4;
  static const double grabBottomGap = 2;
  static const double titleSize = 18;
  static const double subtitleSize = 14;

  static const double fieldGap = 10;
  static const double fieldLabelGap = 7;
  static const double fieldLabelSize = 12;

  static const double stepperButtonSize = 44;
  static const double stepperButtonRadius = 12;
  static const double stepperGap = 8;
  static const double stepperValueHeight = 56;
  static const double stepperValueRadius = 12;
  static const double stepperValueSize = 24;
  static const double stepperBorderWidth = 1.5;

  static const double inputMinHeight = 52;
  static const double inputRadius = 12;
  static const EdgeInsets inputPadding = EdgeInsets.symmetric(horizontal: 14);
  static const double inputTextSize = 16;

  static const double sectionLabelSize = 11;
  static const double sectionSpacing = 0.09 * sectionLabelSize;
  static const double linkSize = 12;

  static const EdgeInsets allocPadding = EdgeInsets.symmetric(horizontal: 13, vertical: 11);
  static const double allocRadius = 10;
  static const double allocGap = 11;
  static const double pillSize = 34;
  static const double pillTextSize = 12;
  static const double allocTitleSize = 14;
  static const double allocSubSize = 12;

  static const EdgeInsets totalPadding = EdgeInsets.symmetric(horizontal: 16, vertical: 14);
  static const double totalRadius = 12;
  static const double totalKeySize = 13;
  static const double totalValueSize = 18;

  static const EdgeInsets editRowPadding = EdgeInsets.symmetric(horizontal: 12, vertical: 10);
  static const double editRowRadius = 10;
  static const double editRowGap = 10;
  static const double editLotTitleSize = 13;
  static const double editLotSubSize = 11;
  static const double qtyBoxWidth = 74;
  static const double qtyBoxHeight = 38;
  static const double qtyBoxRadius = 9;
  static const double qtyBoxTextSize = 15;
  static const double qtyBoxBorderWidth = 1.5;

  static const EdgeInsets noticePadding = EdgeInsets.symmetric(horizontal: 13, vertical: 12);
  static const double noticeRadius = 10;
  static const double noticeGap = 10;
  static const double noticeTextSize = 13;
  static const double noticeTextHeight = 1.45;
  static const double noticeIconSize = 20;
}
