import 'package:flutter/material.dart';

/// Raw palette. Nothing outside `app/theme` should reference these directly —
/// widgets read semantic tokens through `context.colors`, which resolves to the
/// light or dark ramp automatically.
class AppColors {
  const AppColors._();

  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  /// Primary — indigo/teal blend chosen as a neutral placeholder brand.
  /// Swap these eight values for the real brand and the whole app follows.
  static const Color primary0Light = Color(0xFFEEF2FF);
  static const Color primary1Light = Color(0xFFDCE3FD);
  static const Color primary2Light = Color(0xFFA9B8F8);
  static const Color primary3Light = Color(0xFF6C82E8);
  static const Color primary4Light = Color(0xFF4356C9);
  static const Color primary5Light = Color(0xFF2E3C96);

  static const Color primary0Dark = Color(0xFF1A1E33);
  static const Color primary1Dark = Color(0xFF232A47);
  static const Color primary2Dark = Color(0xFF3A4478);
  static const Color primary3Dark = Color(0xFF7185E8);
  static const Color primary4Dark = Color(0xFF8E9EF2);
  static const Color primary5Dark = Color(0xFFB9C3F8);

  /// Neutral — 0 is the furthest from the text colour (surface), 9 the closest
  /// (primary text). The dark ramp inverts that relationship.
  static const Color neutral0Light = Color(0xFFFFFFFF);
  static const Color neutral1Light = Color(0xFFF6F8FA);
  static const Color neutral2Light = Color(0xFFEAEEF2);
  static const Color neutral3Light = Color(0xFFD8DEE4);
  static const Color neutral4Light = Color(0xFFAFB8C1);
  static const Color neutral5Light = Color(0xFF8C959F);
  static const Color neutral6Light = Color(0xFF6E7781);
  static const Color neutral7Light = Color(0xFF424A53);
  static const Color neutral8Light = Color(0xFF32383F);
  static const Color neutral9Light = Color(0xFF1F2328);

  static const Color neutral0Dark = Color(0xFF0D1117);
  static const Color neutral1Dark = Color(0xFF151B23);
  static const Color neutral2Dark = Color(0xFF1E252E);
  static const Color neutral3Dark = Color(0xFF2A313C);
  static const Color neutral4Dark = Color(0xFF3D444D);
  static const Color neutral5Dark = Color(0xFF656C76);
  static const Color neutral6Dark = Color(0xFF8B949E);
  static const Color neutral7Dark = Color(0xFFB1BAC4);
  static const Color neutral8Dark = Color(0xFFD1D7DE);
  static const Color neutral9Dark = Color(0xFFF0F6FC);

  /// Success
  static const Color green0Light = Color(0xFFDFFCF0);
  static const Color green1Light = Color(0xFFBAF3DB);
  static const Color green5Light = Color(0xFF1A7F5A);

  static const Color green0Dark = Color(0xFF0C2C22);
  static const Color green1Dark = Color(0xFF14503C);
  static const Color green5Dark = Color(0xFF3FB98A);

  /// Danger
  static const Color red0Light = Color(0xFFFFEDEB);
  static const Color red5Light = Color(0xFFC93A28);

  static const Color red0Dark = Color(0xFF3A1614);
  static const Color red5Dark = Color(0xFFF2705C);

  /// Warning
  static const Color orange5Light = Color(0xFFB45C06);
  static const Color orange5Dark = Color(0xFFE8944A);

  /// Info
  static const Color blue5Light = Color(0xFF1D6AE0);
  static const Color blue5Dark = Color(0xFF5B9BF5);
}
