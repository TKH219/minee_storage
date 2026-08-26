import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// The frame every screen in this design is drawn and QA'd at.
const Size designFrame = Size(390, 844);

/// Sizes the test surface to the design's own frame, so a sheet measured at
/// 82% or 76% of the screen holds what the design says it holds. The default
/// 800×600 window is shorter than the phone and silently drops rows.
void useDesignFrame(WidgetTester tester, {Size size = designFrame}) {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}
